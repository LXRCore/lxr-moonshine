--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-MOONSHINE — Shared rules: recipes, placement, timing
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

LXRMoonshine = LXRMoonshine or {}
local S = LXRMoonshine

function S.Recipe(id) for _, r in ipairs(Config.Recipes) do if r.id == id then return r end end end

local function dist(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + (a.z - b.z) ^ 2) end

---May a still stand here? Returns false, reason when not.
function S.MayStand(pos, stills)
    for _, t in ipairs(Config.Still.towns) do if dist(pos, t.coords) <= t.radius then return false, 'town' end end
    for _, s in pairs(stills or {}) do if dist(pos, s) < Config.Still.spacing then return false, 'too_close' end end
    return true
end

---Does this inventory count function cover a recipe? count(name) → n. Returns true or false, missing item.
function S.Covers(recipe, count)
    for _, line in ipairs(recipe.input) do if (count(line.item) or 0) < line.amount then return false, line.item end end
    return true
end

---Seconds left on a working still.
function S.Left(still, now)
    if not still.recipe or not still.done_at then return 0 end
    return math.max(0, still.done_at - now)
end

---Is the run finished?
function S.Ready(still, now) return still.recipe ~= nil and still.done_at ~= nil and now >= still.done_at end

---Everything the recipes touch.
function S.Items()
    local set, out = {}, {}
    for _, r in ipairs(Config.Recipes) do for _, l in ipairs(r.input) do set[l.item] = true end for _, l in ipairs(r.output) do set[l.item] = true end end
    for k in pairs(set) do out[#out + 1] = k end
    table.sort(out)
    return out
end
