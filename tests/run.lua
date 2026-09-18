--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-MOONSHINE — Offline tests: recipes from the catalog, placement, timing, locale parity
     Usage (from the lxr-moonshine folder):  lua tests/run.lua [--mock out.js en|ka]
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local CORE = os.getenv('LXR_CORE_PATH') or '../lxr-core'
package.path = CORE .. '/?.lua;' .. package.path
local ok = pcall(function() require('tests.lib.fxshim') end)
if not ok then print('lxr-core shim not found at ' .. CORE) os.exit(2) end
local Shim = require('tests.lib.fxshim')
for _, f in ipairs({ 'shared/main.lua', 'shared/locale.lua', 'locales/en.lua', 'config.lua', 'shared/catalog.lua', 'shared/items.lua', 'shared/prices.lua' }) do Shim.load(CORE .. '/' .. f) end
Config = nil Locale = nil
Shim.load('shared/locale.lua') Shim.load('locales/en.lua') Shim.load('locales/ka.lua') Shim.load('config.lua') Shim.load('shared/rules.lua')
local S = LXRMoonshine

local passed, failed = 0, 0
local function test(name, fn) local okT, err = xpcall(fn, debug.traceback) if okT then passed = passed + 1 print('  ^ ok   ' .. name) else failed = failed + 1 print('  x FAIL ' .. name .. '\n' .. err) end end
local function eq(a, b, msg) if a ~= b then error((msg or 'eq') .. ': expected ' .. tostring(b) .. ' got ' .. tostring(a), 2) end end

print('lxr-moonshine offline tests')
test('recipes: catalog items in and out, products illegal, worth the run', function()
    for _, item in ipairs(S.Items()) do assert(LXRShared.Items[item], item) end
    for _, r in ipairs(Config.Recipes) do
        assert(r.minutes > 0 and #r.input > 0 and #r.output > 0, r.id)
        assert(S.Recipe(r.id) == r) assert(Locale.Bundles.en['recipe.' .. r.id], 'label ' .. r.id)
        local cost, worth = 0, 0
        for _, l in ipairs(r.input) do cost = cost + LXRShared.ItemValue(l.item) * l.amount end
        for _, l in ipairs(r.output) do worth = worth + LXRShared.ItemValue(l.item) * l.amount assert(LXRShared.Items[l.item].legal == false, l.item .. ' must be illegal') end
        assert(worth > cost, r.id .. ' must pay: ' .. worth .. ' vs ' .. cost)
    end
    assert(S.Recipe('vodka') == nil)
    assert(LXRShared.Items[Config.Still.item] and LXRShared.Items[Config.Still.item].legal == false)
end)
test('placement: not in town, not on top of another still', function()
    assert(S.MayStand({ x = 0, y = 0, z = 0 }, {}))
    local t = Config.Still.towns[1]
    local okT, why = S.MayStand({ x = t.coords.x, y = t.coords.y, z = t.coords.z }, {})
    assert(not okT) eq(why, 'town')
    local okC, why2 = S.MayStand({ x = 0, y = 0, z = 0 }, { { x = 5, y = 0, z = 0 } })
    assert(not okC) eq(why2, 'too_close')
    assert(S.MayStand({ x = 0, y = 0, z = 0 }, { { x = Config.Still.spacing + 1, y = 0, z = 0 } }))
end)
test('covers: the satchel against a recipe', function()
    local r = S.Recipe('run')
    assert(S.Covers(r, function(n) return 99 end))
    local okC, missing = S.Covers(r, function(n) return n == 'corn_mash' and 1 or 0 end)
    assert(not okC) eq(missing, 'glass_jar')
end)
test('timing: left, ready', function()
    local s = { recipe = 'run', done_at = 1000 }
    eq(S.Left(s, 400), 600) eq(S.Left(s, 1500), 0)
    assert(not S.Ready(s, 999)) assert(S.Ready(s, 1000))
    assert(not S.Ready({}, 5000)) eq(S.Left({}, 5000), 0)
end)
test('locale parity', function()
    local en, ka = Locale.Bundles.en, Locale.Bundles.ka
    local missing = {}
    for k in pairs(en) do if ka[k] == nil then missing[#missing + 1] = k end end
    eq(#missing, 0, 'ka missing: ' .. table.concat(missing, ', '))
end)
print(('%d passed, %d failed'):format(passed, failed))
if arg and arg[1] == '--mock' and arg[2] then
    Config.Lang = arg[3] or 'en'
    local rec = {}
    for _, r in ipairs(Config.Recipes) do rec[#rec + 1] = { id = r.id, minutes = r.minutes } end
    local f = assert(io.open(arg[2], 'w'))
    f:write('window.__LXR_MOCK__ = ' .. json.encode({ action = 'show', recipes = rec, payload = { id = 3, recipe = 'run', left = 412, ready = false, mine = true }, lang = Config.Lang, locale = Lang.bundle(), brand = { name = 'The Land of Wolves', theme = 'night' } }) .. ';\n')
    f:close()
    print('mock written to ' .. arg[2])
end
os.exit(failed == 0 and 0 or 1)
