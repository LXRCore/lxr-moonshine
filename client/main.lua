--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-MOONSHINE — Client: the still you can see, and the work on it
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
local LXR = exports['lxr-core']:GetLXR()
local S = LXRMoonshine
local N = Citizen.InvokeNative
local stills, props, busy, nearId = {}, {}, false, nil

local function toast(key, kind, vars) LXRCore.Notify(Lang:t(key, vars), kind or 'info') end
local function page(action, payload) SendNUIMessage({ action = action, payload = payload, brand = LXRCore.Brand, lang = Config.Lang, locale = Lang.bundle() }) end
local function citizenid() local d = LXRCore.Functions.GetPlayerData() return d and d.citizenid end
local function isLaw() local d = LXRCore.Functions.GetPlayerData() local def = d and LXRShared.Jobs[d.job.name] return def and (def.type == 'leo' or def.type == 'federal') and d.job.onduty end
local function work(ms)
    busy = true
    local ped = PlayerPedId()
    N(0x524B54361229154F, ped, joaat(Config.Work.scenario), ms, true, false, false, false)
    Wait(ms)
    ClearPedTasks(ped)
    busy = false
end
local function recipes() local out = {} for _, r in ipairs(Config.Recipes) do out[#out + 1] = { id = r.id, label = Lang:t('recipe.' .. r.id), minutes = r.minutes } end return out end

local function despawn(id)
    local e = props[id]
    if not e then return end
    exports['lxr-interact']:Remove('lxr-moonshine:' .. id)
    if e ~= true and DoesEntityExist(e) then DeleteEntity(e) end
    props[id] = nil
end

local function options(s)
    local opts = {}
    for _, r in ipairs(Config.Recipes) do
        opts[#opts + 1] = { label = Lang:t('ui.load', { recipe = Lang:t('recipe.' .. r.id) }), key = 'J', canInteract = function() local c = stills[s.id] return c and not c.recipe and c.owner == citizenid() and not busy end, onSelect = function()
            work(Config.Work.loadMs)
            local ok, res, extra = LXR.RPC.Server('lxr-moonshine:load', s.id, r.id)
            if not ok then return toast('error.' .. tostring(res), 'error', { label = extra }) end
            toast('info.loaded', 'success', { recipe = Lang:t('recipe.' .. r.id) })
        end }
    end
    opts[#opts + 1] = { label = Lang:t('ui.collect'), key = 'J', canInteract = function() local c = stills[s.id] return c and c.ready and c.owner == citizenid() and not busy end, onSelect = function()
        work(Config.Work.collectMs)
        local ok, res = LXR.RPC.Server('lxr-moonshine:collect', s.id)
        if not ok then return toast('error.' .. tostring(res), 'error') end
        for _, g in ipairs(res) do toast('info.collected', 'success', { amount = g.amount, label = g.label }) end
    end }
    opts[#opts + 1] = { label = Lang:t('ui.pickup'), key = 'E', canInteract = function() local c = stills[s.id] return c and not c.recipe and c.owner == citizenid() and not busy end, onSelect = function()
        local ok, res, extra = LXR.RPC.Server('lxr-moonshine:pickup', s.id)
        if not ok then return toast('error.' .. tostring(res), 'error', { label = extra }) end
        toast('info.picked_up', 'info')
    end }
    opts[#opts + 1] = { label = Lang:t('ui.smash'), key = 'X', canInteract = function() return Config.Risk.lawSmashes and isLaw() and not busy end, onSelect = function()
        work(Config.Work.collectMs)
        local ok, res = LXR.RPC.Server('lxr-moonshine:smash', s.id)
        if not ok then return toast('error.' .. tostring(res), 'error') end
        toast('info.smashed', 'info')
    end }
    return opts
end

local function spawn(s)
    despawn(s.id)
    local hash = joaat(Config.Still.prop)
    if IsModelValid(hash) then
        RequestModel(hash)
        local t = GetGameTimer() + 3000
        while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
        if HasModelLoaded(hash) then
            local e = CreateObject(hash, s.x, s.y, s.z, false, false, false)
            SetEntityHeading(e, s.heading or 0.0)
            PlaceObjectOnGroundProperly(e)
            FreezeEntityPosition(e, true)
            SetModelAsNoLongerNeeded(hash)
            props[s.id] = e
            exports['lxr-interact']:AddEntity('lxr-moonshine:' .. s.id, e, { label = Lang:t('ui.still'), distance = Config.Security.promptDistance, options = options(s) })
            return
        end
    end
    props[s.id] = true
    exports['lxr-interact']:AddPoint('lxr-moonshine:' .. s.id, vector3(s.x, s.y, s.z), { label = Lang:t('ui.still'), distance = Config.Security.promptDistance, options = options(s) })
end

local function card(s) SendNUIMessage({ action = 'show', recipes = recipes(), payload = { id = s.id, recipe = s.recipe, left = s.left, ready = s.ready, mine = s.owner == citizenid() }, brand = LXRCore.Brand, lang = Config.Lang, locale = Lang.bundle() }) end

RegisterNetEvent('lxr-moonshine:client:sync', function(list) for id in pairs(props) do despawn(id) end stills = {} for _, s in ipairs(list) do stills[s.id] = s end end)
RegisterNetEvent('lxr-moonshine:client:update', function(s) stills[s.id] = s if nearId == s.id then card(s) end end)
RegisterNetEvent('lxr-moonshine:client:remove', function(id) despawn(id) stills[id] = nil if nearId == id then nearId = nil page('hide') end end)

RegisterNetEvent('lxr-moonshine:client:place', function()
    if busy then return end
    local ped = PlayerPedId()
    if IsPedOnMount(ped) or IsPedInAnyVehicle(ped, false) then return toast('error.dismount', 'error') end
    local pos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.5, 0.0)
    local ok, z = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 1.0, false)
    if not ok then return toast('error.invalid', 'error') end
    local spot = { x = pos.x, y = pos.y, z = z }
    local may, why = S.MayStand(spot, stills)
    if not may then return toast('error.' .. why, 'error') end
    work(Config.Work.placeMs)
    local res, err = LXR.RPC.Server('lxr-moonshine:place', spot.x, spot.y, spot.z, GetEntityHeading(ped))
    if not res then return toast('error.' .. tostring(err), 'error') end
    toast('info.placed', 'success')
end)

CreateThread(function()
    while GetResourceState('lxr-interact') ~= 'started' do Wait(1000) end
    while true do
        if LocalPlayer.state.isLoggedIn then
            local pos = GetEntityCoords(PlayerPedId())
            local best, bestD = nil, Config.Security.promptDistance + 1.5
            for id, s in pairs(stills) do
                local d = #(pos - vector3(s.x, s.y, s.z))
                if d <= Config.Security.propRange and not props[id] then spawn(s) elseif d > Config.Security.propRange + 20.0 and props[id] then despawn(id) end
                if d < bestD then best, bestD = id, d end
            end
            if best ~= nearId then nearId = best if best then card(stills[best]) else page('hide') end end
        end
        Wait(2000)
    end
end)

RegisterNetEvent('lxr:client:loaded', function() Wait(1500) TriggerServerEvent('lxr-moonshine:server:ready') end)
RegisterNetEvent('lxr:client:unloaded', function() for id in pairs(props) do despawn(id) end stills = {} nearId = nil page('hide') end)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then for id in pairs(props) do despawn(id) end end end)
CreateThread(function() Wait(2000) if LocalPlayer.state.isLoggedIn then TriggerServerEvent('lxr-moonshine:server:ready') end end)
exports('Stills', function() return stills end)
