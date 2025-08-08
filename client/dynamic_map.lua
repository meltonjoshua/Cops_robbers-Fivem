-- Dynamic Map Features with Roadblocks, Traffic, and Weather
local mapFeatures = {
    roadblocks = {},
    trafficLights = {},
    weatherSystem = {},
    timeSystem = {},
    eventZones = {}
}

-- Configuration
local mapConfig = {
    roadblocks = {
        max_active = 5,
        spawn_chance = 0.3, -- 30% chance when cops request
        duration = 300000, -- 5 minutes
        locations = {
            {coords = {x = 425.0, y = -978.0, z = 30.7}, heading = 90.0, name = "Police Station"},
            {coords = {x = 240.0, y = -862.0, z = 30.0}, heading = 180.0, name = "Downtown"},
            {coords = {x = -1037.0, y = -2738.0, z = 20.0}, heading = 270.0, name = "Airport"},
            {coords = {x = 1729.0, y = 3307.0, z = 41.0}, heading = 45.0, name = "Sandy Shores"},
            {coords = {x = -241.0, y = 6179.0, z = 31.0}, heading = 315.0, name = "Paleto Bay"}
        }
    },
    traffic = {
        density_multiplier = 1.0,
        chaos_events = {
            "traffic_jam", "accident", "construction", "parade"
        },
        chaos_duration = 180000 -- 3 minutes
    },
    weather = {
        change_interval = 300000, -- 5 minutes
        types = {
            "CLEAR", "EXTRASUNNY", "CLOUDS", "OVERCAST", 
            "RAIN", "DRIZZLE", "THUNDER", "FOG"
        },
        effects = {
            rain = {visibility = 0.7, handling = 0.8},
            fog = {visibility = 0.5, handling = 1.0},
            thunder = {visibility = 0.6, handling = 0.7}
        }
    },
    time = {
        speed_multiplier = 1.0, -- Real-time by default
        force_time = false,
        preferred_time = 12 -- Noon
    },
    events = {
        protest = {
            locations = {
                {coords = {x = -265.0, y = -972.0, z = 31.0}, radius = 50.0, name = "City Hall"},
                {coords = {x = 215.0, y = -809.0, z = 31.0}, radius = 30.0, name = "Downtown Square"}
            },
            duration = 600000, -- 10 minutes
            crowd_size = 20
        },
        parade = {
            route = {
                {x = -265.0, y = -972.0, z = 31.0},
                {x = 215.0, y = -809.0, z = 31.0},
                {x = 425.0, y = -978.0, z = 30.7}
            },
            duration = 480000, -- 8 minutes
            speed = 5.0 -- km/h
        }
    }
}

-- Current state
local mapState = {
    currentWeather = "CLEAR",
    currentTime = 12,
    activeRoadblocks = {},
    activeEvents = {},
    trafficChaos = false,
    lastWeatherChange = 0,
    lastEventSpawn = 0
}

-- Initialize dynamic map system
function InitializeDynamicMap()
    CreateThread(function()
        while true do
            if gameActive then
                UpdateWeatherSystem()
                UpdateTimeSystem()
                UpdateTrafficSystem()
                UpdateEventZones()
                UpdateRoadblocks()
            end
            Wait(5000) -- Update every 5 seconds
        end
    end)
    
    ShowNotification("🗺️ Dynamic map system initialized", "info")
end

-- Weather system
function UpdateWeatherSystem()
    local currentTime = GetGameTimer()
    
    if currentTime - mapState.lastWeatherChange > mapConfig.weather.change_interval then
        mapState.lastWeatherChange = currentTime
        
        -- Random weather change during game
        if math.random() < 0.4 then -- 40% chance to change weather
            local newWeather = mapConfig.weather.types[math.random(#mapConfig.weather.types)]
            ChangeWeather(newWeather)
        end
    end
end

function ChangeWeather(weatherType)
    if mapState.currentWeather == weatherType then return end
    
    mapState.currentWeather = weatherType
    SetWeatherTypeNow(weatherType)
    SetWeatherTypeNowPersist(weatherType)
    
    -- Apply weather effects
    local effects = mapConfig.weather.effects[weatherType:lower()]
    if effects then
        ApplyWeatherEffects(effects)
    end
    
    -- Notify players
    local weatherNames = {
        CLEAR = "Clear Skies",
        EXTRASUNNY = "Sunny",
        CLOUDS = "Cloudy",
        OVERCAST = "Overcast",
        RAIN = "Rain",
        DRIZZLE = "Light Rain",
        THUNDER = "Thunderstorm",
        FOG = "Fog"
    }
    
    ShowNotification("🌤️ Weather changed: " .. (weatherNames[weatherType] or weatherType), "info")
    
    if exports.audio_system then
        exports.audio_system:PlaySoundEffect("weather_change")
    end
end

function ApplyWeatherEffects(effects)
    -- Apply visibility effects
    if effects.visibility then
        SetTimecycleModifier("hud_def_blur")
        SetTimecycleModifierStrength(1.0 - effects.visibility)
    end
    
    -- Vehicle handling effects would be applied in vehicle system
    if exports.vehicle_system and effects.handling then
        -- Notify vehicle system of weather effects
        TriggerEvent('cr:weatherEffects', effects.handling)
    end
end

-- Time system
function UpdateTimeSystem()
    if mapConfig.time.force_time then
        NetworkOverrideClockTime(mapConfig.time.preferred_time, 0, 0)
    elseif mapConfig.time.speed_multiplier ~= 1.0 then
        -- Accelerated time
        local currentHour = GetClockHours()
        local newHour = currentHour + (mapConfig.time.speed_multiplier / 60.0)
        NetworkOverrideClockTime(math.floor(newHour) % 24, 0, 0)
    end
end

-- Traffic system
function UpdateTrafficSystem()
    -- Dynamic traffic density based on game mode and activity
    local density = mapConfig.traffic.density_multiplier
    
    if exports.game_modes then
        local mode = exports.game_modes:GetCurrentGameMode()
        if mode == "bank_heist" then
            density = density * 1.5 -- More traffic during heist
        elseif mode == "territory_control" then
            density = density * 0.7 -- Less traffic for territory battles
        end
    end
    
    SetVehicleDensityMultiplierThisFrame(density)
    SetRandomVehicleDensityMultiplierThisFrame(density)
    SetParkedVehicleDensityMultiplierThisFrame(density)
    
    -- Random chaos events
    if not mapState.trafficChaos and math.random() < 0.05 then -- 5% chance per update
        StartTrafficChaos()
    end
end

function StartTrafficChaos()
    mapState.trafficChaos = true
    local chaosType = mapConfig.traffic.chaos_events[math.random(#mapConfig.traffic.chaos_events)]
    
    ShowNotification("🚨 Traffic Alert: " .. chaosType:gsub("_", " "):upper() .. " reported!", "warning")
    
    CreateThread(function()
        Wait(mapConfig.traffic.chaos_duration)
        mapState.trafficChaos = false
        ShowNotification("✅ Traffic situation resolved", "success")
    end)
    
    -- Apply chaos effects
    if chaosType == "traffic_jam" then
        SetVehicleDensityMultiplierThisFrame(3.0)
    elseif chaosType == "accident" then
        SpawnTrafficAccident()
    elseif chaosType == "construction" then
        SpawnConstructionZone()
    elseif chaosType == "parade" then
        StartParadeEvent()
    end
end

-- Roadblock system
function SpawnRoadblock(locationIndex, duration)
    if #mapState.activeRoadblocks >= mapConfig.roadblocks.max_active then
        return false
    end
    
    local location = mapConfig.roadblocks.locations[locationIndex]
    if not location then return false end
    
    local roadblock = {
        id = #mapState.activeRoadblocks + 1,
        location = location,
        props = {},
        vehicles = {},
        peds = {},
        endTime = GetGameTimer() + (duration or mapConfig.roadblocks.duration)
    }
    
    -- Spawn roadblock props
    CreateRoadblockProps(roadblock)
    
    -- Spawn police vehicles and officers
    CreateRoadblockPersonnel(roadblock)
    
    table.insert(mapState.activeRoadblocks, roadblock)
    
    -- Notify players
    ShowNotification("🚧 Police roadblock established at " .. location.name, "warning")
    
    -- Create map blip
    roadblock.blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
    SetBlipSprite(roadblock.blip, 161) -- Police station icon
    SetBlipColour(roadblock.blip, 1) -- Red
    SetBlipScale(roadblock.blip, 0.8)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Police Roadblock")
    EndTextCommandSetBlipName(roadblock.blip)
    
    return true
end

function CreateRoadblockProps(roadblock)
    local coords = roadblock.location.coords
    local heading = roadblock.location.heading
    
    -- Spawn barrier props
    local barrierModel = GetHashKey("prop_barrier_work05")
    RequestModel(barrierModel)
    
    while not HasModelLoaded(barrierModel) do
        Wait(1)
    end
    
    for i = -2, 2 do
        local x = coords.x + (math.cos(math.rad(heading)) * i * 3.0)
        local y = coords.y + (math.sin(math.rad(heading)) * i * 3.0)
        
        local barrier = CreateObject(barrierModel, x, y, coords.z, true, true, true)
        SetEntityHeading(barrier, heading)
        FreezeEntityPosition(barrier, true)
        table.insert(roadblock.props, barrier)
    end
    
    SetModelAsNoLongerNeeded(barrierModel)
end

function CreateRoadblockPersonnel(roadblock)
    local coords = roadblock.location.coords
    local heading = roadblock.location.heading
    
    -- Spawn police vehicle
    local policeModel = GetHashKey("police")
    RequestModel(policeModel)
    
    while not HasModelLoaded(policeModel) do
        Wait(1)
    end
    
    local vehicle = CreateVehicle(policeModel, coords.x + 5.0, coords.y + 5.0, coords.z, heading, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleSiren(vehicle, true)
    table.insert(roadblock.vehicles, vehicle)
    
    -- Spawn officers
    local officerModel = GetHashKey("s_m_y_cop_01")
    RequestModel(officerModel)
    
    while not HasModelLoaded(officerModel) do
        Wait(1)
    end
    
    for i = 1, 2 do
        local officer = CreatePed(4, officerModel, 
            coords.x + math.random(-3, 3), 
            coords.y + math.random(-3, 3), 
            coords.z, heading, true, false)
        
        SetPedArmour(officer, 100)
        GiveWeaponToPed(officer, GetHashKey("WEAPON_PISTOL"), 200, false, true)
        SetPedAsGroupMember(officer, GetPlayerGroup(PlayerId()))
        
        table.insert(roadblock.peds, officer)
    end
    
    SetModelAsNoLongerNeeded(policeModel)
    SetModelAsNoLongerNeeded(officerModel)
end

function UpdateRoadblocks()
    local currentTime = GetGameTimer()
    
    for i = #mapState.activeRoadblocks, 1, -1 do
        local roadblock = mapState.activeRoadblocks[i]
        
        if currentTime >= roadblock.endTime then
            RemoveRoadblock(i)
        end
    end
end

function RemoveRoadblock(index)
    local roadblock = mapState.activeRoadblocks[index]
    
    -- Remove props
    for _, prop in ipairs(roadblock.props) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
    
    -- Remove vehicles
    for _, vehicle in ipairs(roadblock.vehicles) do
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end
    
    -- Remove peds
    for _, ped in ipairs(roadblock.peds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    
    -- Remove blip
    if roadblock.blip then
        RemoveBlip(roadblock.blip)
    end
    
    table.remove(mapState.activeRoadblocks, index)
    ShowNotification("✅ Police roadblock cleared", "info")
end

-- Event zones
function UpdateEventZones()
    local currentTime = GetGameTimer()
    
    -- Spawn random events
    if currentTime - mapState.lastEventSpawn > 300000 and math.random() < 0.1 then -- 10% chance every 5 minutes
        mapState.lastEventSpawn = currentTime
        SpawnRandomEvent()
    end
    
    -- Update active events
    for i = #mapState.activeEvents, 1, -1 do
        local event = mapState.activeEvents[i]
        
        if currentTime >= event.endTime then
            RemoveEvent(i)
        end
    end
end

function SpawnRandomEvent()
    local eventTypes = {"protest", "parade"}
    local eventType = eventTypes[math.random(#eventTypes)]
    
    if eventType == "protest" then
        SpawnProtestEvent()
    elseif eventType == "parade" then
        StartParadeEvent()
    end
end

function SpawnProtestEvent()
    local protestConfig = mapConfig.events.protest
    local location = protestConfig.locations[math.random(#protestConfig.locations)]
    
    local event = {
        type = "protest",
        location = location,
        endTime = GetGameTimer() + protestConfig.duration,
        participants = {}
    }
    
    -- Spawn protest participants
    local pedModel = GetHashKey("a_m_m_downtown_01")
    RequestModel(pedModel)
    
    while not HasModelLoaded(pedModel) do
        Wait(1)
    end
    
    for i = 1, protestConfig.crowd_size do
        local x = location.coords.x + math.random(-location.radius, location.radius)
        local y = location.coords.y + math.random(-location.radius, location.radius)
        
        local ped = CreatePed(4, pedModel, x, y, location.coords.z, 0.0, true, false)
        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CHEERING", 0, true)
        
        table.insert(event.participants, ped)
    end
    
    table.insert(mapState.activeEvents, event)
    ShowNotification("📢 Protest gathering at " .. location.name, "info")
    
    SetModelAsNoLongerNeeded(pedModel)
end

function StartParadeEvent()
    ShowNotification("🎉 Parade blocking main streets!", "warning")
    
    -- Increase traffic density dramatically
    CreateThread(function()
        local endTime = GetGameTimer() + mapConfig.events.parade.duration
        
        while GetGameTimer() < endTime do
            SetVehicleDensityMultiplierThisFrame(5.0)
            Wait(0)
        end
        
        ShowNotification("✅ Parade has ended", "info")
    end)
end

function RemoveEvent(index)
    local event = mapState.activeEvents[index]
    
    if event.type == "protest" then
        for _, ped in ipairs(event.participants) do
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
            end
        end
    end
    
    table.remove(mapState.activeEvents, index)
end

-- Commands for admin/testing
RegisterCommand('spawn_roadblock', function(source, args)
    if args[1] then
        local locationIndex = tonumber(args[1])
        if SpawnRoadblock(locationIndex) then
            ShowNotification("🚧 Roadblock spawned at location " .. locationIndex, "success")
        else
            ShowNotification("❌ Failed to spawn roadblock", "error")
        end
    else
        ShowNotification("Usage: /spawn_roadblock [location_index]", "info")
    end
end, false)

RegisterCommand('change_weather', function(source, args)
    if args[1] then
        local weather = args[1]:upper()
        ChangeWeather(weather)
    else
        ShowNotification("Usage: /change_weather [type]", "info")
    end
end, false)

RegisterCommand('traffic_chaos', function()
    StartTrafficChaos()
end, false)

RegisterCommand('clear_roadblocks', function()
    for i = #mapState.activeRoadblocks, 1, -1 do
        RemoveRoadblock(i)
    end
    ShowNotification("✅ All roadblocks cleared", "success")
end, false)

-- Event handlers
RegisterNetEvent('cr:requestRoadblock')
AddEventHandler('cr:requestRoadblock', function(locationIndex)
    if playerTeam == "cop" and math.random() < mapConfig.roadblocks.spawn_chance then
        SpawnRoadblock(locationIndex)
    end
end)

RegisterNetEvent('cr:changeWeather')
AddEventHandler('cr:changeWeather', function(weather)
    ChangeWeather(weather)
end)

-- Initialize when script starts
CreateThread(function()
    Wait(3000) -- Wait for other systems
    InitializeDynamicMap()
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Clean up all spawned entities
        for i = #mapState.activeRoadblocks, 1, -1 do
            RemoveRoadblock(i)
        end
        
        for i = #mapState.activeEvents, 1, -1 do
            RemoveEvent(i)
        end
    end
end)

-- Export functions
exports('SpawnRoadblock', SpawnRoadblock)
exports('ChangeWeather', ChangeWeather)
exports('GetMapState', function() return mapState end)
exports('StartTrafficChaos', StartTrafficChaos)
