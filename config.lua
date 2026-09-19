--[[
    ██╗     ██╗  ██╗██████╗       ███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗███████╗██╗  ██╗██╗███╗   ██╗███████╗
    ██║     ╚██╗██╔╝██╔══██╗      ████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║██╔════╝██║  ██║██║████╗  ██║██╔════╝
    ██║      ╚███╔╝ ██████╔╝█████╗██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║███████╗███████║██║██╔██╗ ██║█████╗
    ██║      ██╔██╗ ██╔══██╗╚════╝██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║╚════██║██╔══██║██║██║╚██╗██║██╔══╝
    ███████╗██╔╝ ██╗██║  ██║      ██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║███████║██║  ██║██║██║ ╚████║███████╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝

    LXR Core - Moonshine

    A copper still set up somewhere the law does not ride. Corn from the
    field, sugar from the store, yeast, jars — and time. Stills live on the
    server and survive restarts; a working still can put a call on the wire,
    and the law can smash it. Everything in and out is the core catalog's:
    the mash is illegal, the liquor is illegal, the fence and the contraband
    contacts already know what to do with it.

    Brand:       LXRCore — Lux Empire eXperience RedM Core
    Product:     wolves.land / The Land of Wolves
    Developer:   iBoss21 / LXRCore
    Website:     https://www.lxrcore.com
    Discord:     https://discord.gg/GAhk8cgXe9
    GitHub:      https://github.com/LXRCore

    Version: 3.0.0
    Performance Target: 0.00 ms idle (interact points; one 60 s tick on the server)

    © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
]]

Config = Config or {}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ LANGUAGE ██████████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
Config.Lang = 'en'

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ THE STILL ═════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
Config.Still = {
    item = 'still_kit',               -- placed with the item, taken back when idle
    prop = 'p_still01x',              -- best guess; a model that fails IsModelValid is skipped and the still is still marked by its prompt
    perPlayer = 1,
    spacing = 25.0,                   -- between stills
    towns = {                         -- no stills within these radii
        { coords = vector3(-300.0, 790.0, 118.0), radius = 300.0 },   -- Valentine
        { coords = vector3(1330.0, -1300.0, 77.0), radius = 300.0 },  -- Rhodes
        { coords = vector3(2640.0, -1220.0, 53.0), radius = 500.0 },  -- Saint Denis
        { coords = vector3(-820.0, -1320.0, 43.0), radius = 300.0 },  -- Blackwater
        { coords = vector3(-3660.0, -2620.0, -13.0), radius = 300.0 }, -- Armadillo
        { coords = vector3(-5500.0, -2940.0, -2.0), radius = 300.0 },  -- Tumbleweed
        { coords = vector3(-1800.0, -390.0, 160.0), radius = 250.0 },  -- Strawberry
        { coords = vector3(2930.0, 1360.0, 60.0), radius = 250.0 },    -- Annesburg
        { coords = vector3(2970.0, 520.0, 45.0), radius = 200.0 },     -- Van Horn
    },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ RECIPES ═══════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
-- in / out are core catalog items; minutes is real time on the still
Config.Recipes = {
    { id = 'mash',  minutes = 20, input = { { item = 'corn', amount = 4 }, { item = 'sugar', amount = 1 }, { item = 'yeast', amount = 1 } }, output = { { item = 'corn_mash', amount = 1 } } },
    { id = 'run',   minutes = 15, input = { { item = 'corn_mash', amount = 1 }, { item = 'glass_jar', amount = 3 } }, output = { { item = 'moonshine', amount = 3 } } },
    { id = 'age',   minutes = 45, input = { { item = 'moonshine', amount = 3 } }, output = { { item = 'moonshine_fine', amount = 3 } } },
    { id = 'berry', minutes = 30, input = { { item = 'moonshine', amount = 3 }, { item = 'blackberry', amount = 6 } }, output = { { item = 'moonshine_berry', amount = 3 } } },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ THE RISK ══════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
Config.Risk = {
    callChancePerMinute = 0.02,       -- while a still is working, per minute, when law is on duty (lxr-dispatch)
    callKind = 'lawcall',
    lawSmashes = true,                -- the law's option on any still: destroys it, nothing comes back
}

Config.Work = { placeMs = 5000, loadMs = 4000, collectMs = 3000, scenario = 'WORLD_HUMAN_CROUCH_INSPECT' }
Config.Security = { rateLimit = { windowMs = 2000, burst = 6 }, maxDistance = 3.5, promptDistance = 2.0, propRange = 120.0 }
Config.Debug = { printBanner = true, log = true }
