--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-MOONSHINE — Server: the stills live here
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
local LXR = exports['lxr-core']:GetLXR()
local S = LXRMoonshine
local RES = GetCurrentResourceName()
local stills, buckets = {}, {}

local function limited(src)
    local b = buckets[src]
    local now = GetGameTimer()
    if not b or now - b.at > Config.Security.rateLimit.windowMs then b = { at = now, n = 0 } buckets[src] = b end
    b.n = b.n + 1
    return b.n > Config.Security.rateLimit.burst
end
local function player(src) return LXRCore.Functions.GetPlayer(src) end
local function near(src, p)
    local ped = GetPlayerPed(src)
    return ped ~= 0 and #(GetEntityCoords(ped) - vector3(p.x, p.y, p.z)) <= Config.Security.maxDistance
end
local function isLaw(P)
    local def = LXRShared.Jobs[P.PlayerData.job.name]
    return def and (def.type == 'leo' or def.type == 'federal') and P.PlayerData.job.onduty
end
local function lawOnDuty() for _, P in pairs(LXRCore.Players) do if isLaw(P) then return true end end return false end
local function public(s) return { id = s.id, x = s.x, y = s.y, z = s.z, heading = s.heading, owner = s.citizenid, recipe = s.recipe, left = S.Left(s, os.time()), ready = S.Ready(s, os.time()) } end
local function save(s) LXRCore.DB.UpdateAsync('UPDATE lxr_moonshine SET recipe = ?, done_at = ? WHERE id = ?', { s.recipe, s.done_at, s.id }) end
local function broadcast(s) TriggerClientEvent('lxr-moonshine:client:update', -1, public(s)) end
local function remove(id, why)
    local s = stills[id]
    if not s then return end
    stills[id] = nil
    LXRCore.DB.UpdateAsync('DELETE FROM lxr_moonshine WHERE id = ?', { id })
    TriggerClientEvent('lxr-moonshine:client:remove', -1, id, why)
end
local function mine(cid) local n = 0 for _, s in pairs(stills) do if s.citizenid == cid then n = n + 1 end end return n end

LXRCore.DB.RegisterMigration(RES, '0001_moonshine', [[
CREATE TABLE IF NOT EXISTS `lxr_moonshine` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `x` FLOAT NOT NULL, `y` FLOAT NOT NULL, `z` FLOAT NOT NULL, `heading` FLOAT NOT NULL DEFAULT 0,
  `recipe` VARCHAR(32) NULL,
  `done_at` INT NULL,
  `placed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]])

CreateThread(function()
    Wait(1000)
    local rows = LXRCore.DB.Query('SELECT id, citizenid, x, y, z, heading, recipe, done_at FROM lxr_moonshine') or {}
    for _, r in ipairs(rows) do stills[r.id] = { id = r.id, citizenid = r.citizenid, x = r.x, y = r.y, z = r.z, heading = r.heading, recipe = r.recipe, done_at = r.done_at } end
    if Config.Debug.printBanner then print(('^1[lxr-moonshine]^7 v%s — %d recipes, %d stills standing'):format(GetResourceMetadata(RES, 'version', 0), #Config.Recipes, #rows)) end
end)

LXRCore.Items.RegisterUsable(Config.Still.item, function(src) TriggerClientEvent('lxr-moonshine:client:place', src) end)

LXR.RPC.Register('lxr-moonshine:place', function(src, x, y, z, heading)
    if limited(src) then return false, 'rate' end
    local P = player(src)
    if not P or type(x) ~= 'number' or type(y) ~= 'number' or type(z) ~= 'number' then return false, 'invalid' end
    local pos = { x = x, y = y, z = z }
    if not near(src, pos) then return false, 'too_far' end
    local okStand, why = S.MayStand(pos, stills)
    if not okStand then return false, why end
    if mine(P.PlayerData.citizenid) >= Config.Still.perPlayer then return false, 'too_many' end
    if not P.Functions.RemoveItem(Config.Still.item, 1, nil, 'moonshine:place') then return false, 'no_kit' end
    local id = LXRCore.DB.Insert('INSERT INTO lxr_moonshine (citizenid, x, y, z, heading) VALUES (?, ?, ?, ?, ?)', { P.PlayerData.citizenid, x, y, z, tonumber(heading) or 0.0 })
    local s = { id = id, citizenid = P.PlayerData.citizenid, x = x, y = y, z = z, heading = tonumber(heading) or 0.0 }
    stills[id] = s
    TriggerClientEvent('lxr-moonshine:client:update', -1, public(s))
    LXRCore.Emit('lxr:moonshine:placed', nil, src, id)
    return true, id
end)

LXR.RPC.Register('lxr-moonshine:load', function(src, id, recipeId)
    if limited(src) then return false, 'rate' end
    local P, s, r = player(src), stills[tonumber(id) or 0], S.Recipe(recipeId)
    if not P or not s or not r then return false, 'invalid' end
    if not near(src, s) then return false, 'too_far' end
    if s.citizenid ~= P.PlayerData.citizenid then return false, 'not_yours' end
    if s.recipe then return false, 'busy' end
    local covered, missing = S.Covers(r, function(n) return LXRCore.Inventory.GetItemCount(src, n) end)
    if not covered then return false, 'missing', LXRShared.Items[missing].label end
    for _, line in ipairs(r.input) do if not P.Functions.RemoveItem(line.item, line.amount, nil, 'moonshine:' .. r.id) then return false, 'missing', LXRShared.Items[line.item].label end end
    s.recipe, s.done_at = r.id, os.time() + r.minutes * 60
    save(s) broadcast(s)
    LXRCore.Emit('lxr:moonshine:loaded', nil, src, id, r.id)
    return true, public(s)
end)

LXR.RPC.Register('lxr-moonshine:collect', function(src, id)
    if limited(src) then return false, 'rate' end
    local P, s = player(src), stills[tonumber(id) or 0]
    if not P or not s then return false, 'invalid' end
    if not near(src, s) then return false, 'too_far' end
    if s.citizenid ~= P.PlayerData.citizenid then return false, 'not_yours' end
    if not S.Ready(s, os.time()) then return false, 'not_ready' end
    local r = S.Recipe(s.recipe)
    local got = {}
    for _, line in ipairs(r.output) do
        if not LXRCore.Inventory.CanCarry(src, line.item, line.amount) then return false, 'too_heavy', LXRShared.Items[line.item].label end
    end
    for _, line in ipairs(r.output) do P.Functions.AddItem(line.item, line.amount, nil, nil, 'moonshine:' .. r.id) got[#got + 1] = { item = line.item, label = LXRShared.Items[line.item].label, amount = line.amount } end
    s.recipe, s.done_at = nil, nil
    save(s) broadcast(s)
    LXRCore.Emit('lxr:moonshine:collected', nil, src, id, r.id, got)
    if Config.Debug.log then LXRCore.Log.info('moonshine', ('collected %s from still %d'):format(r.id, id), { source = src }) end
    return true, got
end)

LXR.RPC.Register('lxr-moonshine:pickup', function(src, id)
    if limited(src) then return false, 'rate' end
    local P, s = player(src), stills[tonumber(id) or 0]
    if not P or not s then return false, 'invalid' end
    if not near(src, s) then return false, 'too_far' end
    if s.citizenid ~= P.PlayerData.citizenid then return false, 'not_yours' end
    if s.recipe then return false, 'busy' end
    if not LXRCore.Inventory.CanCarry(src, Config.Still.item, 1) then return false, 'too_heavy', LXRShared.Items[Config.Still.item].label end
    P.Functions.AddItem(Config.Still.item, 1, nil, nil, 'moonshine:pickup')
    remove(s.id, 'pickup')
    return true
end)

LXR.RPC.Register('lxr-moonshine:smash', function(src, id)
    if limited(src) then return false, 'rate' end
    local P, s = player(src), stills[tonumber(id) or 0]
    if not P or not s then return false, 'invalid' end
    if not near(src, s) then return false, 'too_far' end
    if not (Config.Risk.lawSmashes and isLaw(P)) then return false, 'not_law' end
    remove(s.id, 'smash')
    LXRCore.Emit('lxr:moonshine:smashed', nil, src, id, s.citizenid)
    if Config.Debug.log then LXRCore.Log.info('moonshine', ('still %d smashed'):format(id), { source = src }) end
    return true
end)

RegisterNetEvent('lxr-moonshine:server:ready', function()
    local src = source
    local list = {}
    for _, s in pairs(stills) do list[#list + 1] = public(s) end
    TriggerClientEvent('lxr-moonshine:client:sync', src, list)
end)

CreateThread(function()
    while true do
        Wait(60000)
        local now = os.time()
        local law = nil
        for _, s in pairs(stills) do
            if s.recipe and not S.Ready(s, now) then
                if law == nil then law = lawOnDuty() and GetResourceState('lxr-dispatch') == 'started' end
                if law and math.random() < Config.Risk.callChancePerMinute then
                    exports['lxr-dispatch']:Raise({ kind = Config.Risk.callKind, coords = vector3(s.x, s.y, s.z), title = Lang:t('call.still'), message = Lang:t('call.still_msg') })
                end
            elseif s.recipe and S.Ready(s, now) and not s.announced then
                s.announced = true broadcast(s)
            end
        end
    end
end)

AddEventHandler('playerDropped', function() buckets[source] = nil end)
exports('Stills', function(cid) local out = {} for _, s in pairs(stills) do if not cid or s.citizenid == cid then out[#out + 1] = public(s) end end return out end)
exports('Remove', function(id) remove(tonumber(id), 'export') end)
