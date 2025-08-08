-- Advanced Vehicle System with Damage, Fuel, and Modifications
local vehicleData = {}
local fuelEnabled = true
local damageEnabled = true
local modificationsEnabled = true

-- Vehicle configuration
local vehicleConfig = {
    fuel = {
        consumption_rate = {
            idle = 0.1,         -- Per minute while idling
            driving = 0.5,      -- Per minute while driving normally
            speeding = 1.2,     -- Per minute while speeding (>80 km/h)
            offroad = 0.8       -- Per minute while off-road
        },
        tank_capacity = {
            default = 100.0,
            motorcycle = 60.0,
            truck = 150.0,
            helicopter = 200.0
        },
        stations = {
            {coords = {x = 49.4, y = 2778.7, z = 58.0}, name = "Ron Gas Station"},
            {coords = {x = 263.9, y = 2606.5, z = 44.9}, name = "Xero Gas Station"},
            {coords = {x = 1039.9, y = 2671.1, z = 39.5}, name = "LTD Gas Station"},
            {coords = {x = 1207.3, y = 2660.2, z = 37.9}, name = "Route 68 Station"},
            {coords = {x = 2679.9, y = 3264.2, z = 55.2}, name = "Sandy Shores Station"}
        }
    },
    damage = {
        engine_degradation = 0.1,    -- Damage per collision
        body_degradation = 0.05,     -- Visual damage per collision
        wheel_damage_threshold = 50.0, -- Speed threshold for wheel damage
        fire_threshold = 10.0,       -- Health threshold for fire
        explosion_threshold = 5.0     -- Health threshold for explosion
    },
    modifications = {
        speed_boost = {
            name = "Turbo Upgrade",
            cost = 5000,
            multiplier = 1.3,
            description = "Increases top speed by 30%"
        },
        armor_upgrade = {
            name = "Armor Plating",
            cost = 7500,
            protection = 0.5,
            description = "Reduces damage taken by 50%"
        },
        fuel_efficiency = {
            name = "Fuel Efficiency",
            cost = 3000,
            efficiency = 0.7,
            description = "Reduces fuel consumption by 30%"
        },
        handling_upgrade = {
            name = "Racing Suspension",
            cost = 4000,
            handling = 1.2,
            description = "Improves handling and cornering"
        }
    }
}

-- Initialize vehicle when player enters
function InitializeVehicle(vehicle)
    if not vehicle or vehicle == 0 then return end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    
    if not vehicleData[plate] then
        vehicleData[plate] = {
            fuel = GetVehicleFuelCapacity(vehicle),
            health = 1000.0,
            engine_health = 1000.0,
            body_health = 1000.0,
            modifications = {},
            last_update = GetGameTimer(),
            total_distance = 0.0,
            last_position = GetEntityCoords(vehicle)
        }
    end
    
    ApplyVehicleModifications(vehicle, plate)
end

-- Get vehicle fuel capacity based on type
function GetVehicleFuelCapacity(vehicle)
    local vehicleClass = GetVehicleClass(vehicle)
    
    if vehicleClass == 8 then -- Motorcycles
        return vehicleConfig.fuel.tank_capacity.motorcycle
    elseif vehicleClass == 20 then -- Industrial
        return vehicleConfig.fuel.tank_capacity.truck
    elseif vehicleClass == 15 or vehicleClass == 16 then -- Helicopters/Planes
        return vehicleConfig.fuel.tank_capacity.helicopter
    else
        return vehicleConfig.fuel.tank_capacity.default
    end
end

-- Update vehicle systems
function UpdateVehicleSystems()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then return end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    local data = vehicleData[plate]
    
    if not data then
        InitializeVehicle(vehicle)
        data = vehicleData[plate]
    end
    
    local currentTime = GetGameTimer()
    local deltaTime = (currentTime - data.last_update) / 60000.0 -- Convert to minutes
    data.last_update = currentTime
    
    -- Update fuel consumption
    if fuelEnabled then
        UpdateFuelConsumption(vehicle, plate, deltaTime)
    end
    
    -- Update damage system
    if damageEnabled then
        UpdateVehicleDamage(vehicle, plate)
    end
    
    -- Update distance tracking
    UpdateDistanceTracking(vehicle, plate)
    
    -- Update UI
    UpdateVehicleUI(vehicle, plate)
end

-- Update fuel consumption
function UpdateFuelConsumption(vehicle, plate, deltaTime)
    local data = vehicleData[plate]
    local speed = GetEntitySpeed(vehicle) * 3.6 -- Convert to km/h
    local rpm = GetVehicleCurrentRpm(vehicle)
    
    local consumption = 0
    
    if speed < 5.0 and rpm > 0.1 then
        -- Idling
        consumption = vehicleConfig.fuel.consumption_rate.idle * deltaTime
    elseif speed > 80.0 then
        -- Speeding
        consumption = vehicleConfig.fuel.consumption_rate.speeding * deltaTime
    else
        -- Normal driving
        consumption = vehicleConfig.fuel.consumption_rate.driving * deltaTime
    end
    
    -- Check if off-road
    local surfaceMaterial = GetVehicleWheelSurfaceMaterial(vehicle, 0)
    if surfaceMaterial == 1 or surfaceMaterial == 3 then -- Dirt or sand
        consumption = consumption * 1.5 -- 50% more consumption off-road
    end
    
    -- Apply fuel efficiency modifications
    if data.modifications.fuel_efficiency then
        consumption = consumption * vehicleConfig.modifications.fuel_efficiency.efficiency
    end
    
    data.fuel = math.max(0, data.fuel - consumption)
    
    -- Handle empty fuel
    if data.fuel <= 0 then
        SetVehicleEngineOn(vehicle, false, true, true)
        SetVehicleUndriveable(vehicle, true)
        
        if data.fuel <= -1 then -- Show notification only once
            ShowNotification("⛽ Vehicle out of fuel! Find a gas station.", "warning")
            data.fuel = 0 -- Prevent multiple notifications
        end
    end
end

-- Update vehicle damage
function UpdateVehicleDamage(vehicle, plate)
    local data = vehicleData[plate]
    local currentHealth = GetVehicleEngineHealth(vehicle)
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    
    -- Check for collisions
    if HasEntityCollidedWithAnything(vehicle) then
        local speed = GetEntitySpeed(vehicle) * 3.6
        
        if speed > vehicleConfig.damage.wheel_damage_threshold then
            -- High-speed collision
            local damage = math.min(100, speed / 2)
            data.engine_health = math.max(0, data.engine_health - damage)
            data.body_health = math.max(0, data.body_health - damage / 2)
            
            SetVehicleEngineHealth(vehicle, data.engine_health)
            SetVehicleBodyHealth(vehicle, data.body_health)
            
            -- Chance to damage wheels
            if math.random() < 0.3 then
                SetVehicleTyreBurst(vehicle, math.random(0, 3), false, 1000.0)
                ShowNotification("💥 Tire damaged from impact!", "warning")
            end
        end
    end
    
    -- Apply armor protection
    if data.modifications.armor_upgrade then
        local protection = vehicleConfig.modifications.armor_upgrade.protection
        if currentHealth < data.engine_health then
            local actualDamage = (data.engine_health - currentHealth) * protection
            SetVehicleEngineHealth(vehicle, data.engine_health - actualDamage)
        end
    end
    
    -- Check for fire and explosion
    if data.engine_health <= vehicleConfig.damage.fire_threshold then
        if not IsVehicleOnFire(vehicle) then
            StartEntityFire(vehicle)
            ShowNotification("🔥 Vehicle engine is on fire!", "error")
        end
    end
    
    if data.engine_health <= vehicleConfig.damage.explosion_threshold then
        if math.random() < 0.1 then -- 10% chance per update
            SetVehicleEngineOn(vehicle, false, true, true)
            ShowNotification("💥 Critical engine failure!", "error")
        end
    end
end

-- Update distance tracking
function UpdateDistanceTracking(vehicle, plate)
    local data = vehicleData[plate]
    local currentPos = GetEntityCoords(vehicle)
    
    if data.last_position then
        local distance = #(currentPos - data.last_position)
        data.total_distance = data.total_distance + distance
    end
    
    data.last_position = currentPos
end

-- Update vehicle UI
function UpdateVehicleUI(vehicle, plate)
    local data = vehicleData[plate]
    local maxFuel = GetVehicleFuelCapacity(vehicle)
    local fuelPercent = (data.fuel / maxFuel) * 100
    local healthPercent = (data.engine_health / 1000.0) * 100
    
    SendNUIMessage({
        type = "updateVehicleInfo",
        fuel = math.floor(fuelPercent),
        health = math.floor(healthPercent),
        distance = math.floor(data.total_distance / 1000), -- Convert to km
        modifications = data.modifications
    })
    
    -- Fuel warning
    if fuelPercent <= 20 and fuelPercent > 0 then
        SendNUIMessage({
            type = "showFuelWarning",
            level = fuelPercent <= 10 and "critical" or "low"
        })
    end
end

-- Refuel at gas stations
function CheckGasStations()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if vehicle == 0 then return end
    
    for _, station in ipairs(vehicleConfig.fuel.stations) do
        local distance = #(playerCoords - vector3(station.coords.x, station.coords.y, station.coords.z))
        
        if distance <= 10.0 then
            DrawText3D(station.coords.x, station.coords.y, station.coords.z + 2.0, 
                "~g~[E]~w~ " .. station.name .. " - Refuel Vehicle")
            
            if IsControlJustPressed(0, 38) then -- E key
                StartRefueling(vehicle, station)
            end
            break
        end
    end
end

-- Start refueling process
function StartRefueling(vehicle, station)
    local plate = GetVehicleNumberPlateText(vehicle)
    local data = vehicleData[plate]
    local maxFuel = GetVehicleFuelCapacity(vehicle)
    local fuelNeeded = maxFuel - data.fuel
    local cost = math.ceil(fuelNeeded * 2) -- $2 per unit
    
    if fuelNeeded <= 0 then
        ShowNotification("⛽ Vehicle already has full fuel!", "info")
        return
    end
    
    ShowNotification("⛽ Refueling... Cost: $" .. cost, "info")
    
    -- Refueling animation
    TaskStartScenarioInPlace(PlayerPedId(), "PROP_HUMAN_PARKING_METER", 0, true)
    
    CreateThread(function()
        local refuelTime = math.min(10000, fuelNeeded * 100) -- Max 10 seconds
        local startTime = GetGameTimer()
        
        while GetGameTimer() - startTime < refuelTime do
            local progress = (GetGameTimer() - startTime) / refuelTime
            local currentFuel = data.fuel + (fuelNeeded * progress)
            
            DrawText3D(station.coords.x, station.coords.y, station.coords.z + 2.0, 
                "~y~Refueling... " .. math.floor(progress * 100) .. "%")
            
            data.fuel = currentFuel
            Wait(100)
        end
        
        ClearPedTasksImmediately(PlayerPedId())
        data.fuel = maxFuel
        
        ShowNotification("⛽ Refueling complete! Cost: $" .. cost, "success")
        
        -- Deduct money (integrate with economy system)
        TriggerServerEvent('cr:purchaseFuel', cost)
        
        -- Play sound effect
        if exports.audio_system then
            exports.audio_system:PlaySoundEffect("fuel_complete")
        end
    end)
end

-- Vehicle modification system
function ShowModificationMenu(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    local data = vehicleData[plate]
    
    SendNUIMessage({
        type = "showModificationMenu",
        vehicle = {
            model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
            plate = plate,
            modifications = data.modifications
        },
        availableMods = vehicleConfig.modifications
    })
    
    SetNuiFocus(true, true)
end

-- Apply vehicle modifications
function ApplyVehicleModifications(vehicle, plate)
    local data = vehicleData[plate]
    
    for modType, modData in pairs(data.modifications) do
        if modType == "speed_boost" then
            ModifyVehicleTopSpeed(vehicle, vehicleConfig.modifications.speed_boost.multiplier)
        elseif modType == "handling_upgrade" then
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMin", 
                GetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMin") * 
                vehicleConfig.modifications.handling_upgrade.handling)
        end
    end
end

-- Purchase modification
function PurchaseModification(vehicle, modType)
    local plate = GetVehicleNumberPlateText(vehicle)
    local data = vehicleData[plate]
    local mod = vehicleConfig.modifications[modType]
    
    if not mod then return false end
    if data.modifications[modType] then
        ShowNotification("🔧 Vehicle already has this modification!", "error")
        return false
    end
    
    -- Check if player has enough money (integrate with economy)
    TriggerServerEvent('cr:purchaseModification', modType, mod.cost, function(success)
        if success then
            data.modifications[modType] = true
            ApplyVehicleModifications(vehicle, plate)
            ShowNotification("🔧 " .. mod.name .. " installed!", "success")
        else
            ShowNotification("💰 Not enough money for this modification!", "error")
        end
    end)
end

-- Draw 3D text
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Main update thread
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        if vehicle ~= 0 then
            UpdateVehicleSystems()
        end
        
        CheckGasStations()
        Wait(1000)
    end
end)

-- Event handlers
RegisterNetEvent('cr:enableVehicleSystems')
AddEventHandler('cr:enableVehicleSystems', function(fuel, damage, mods)
    fuelEnabled = fuel
    damageEnabled = damage
    modificationsEnabled = mods
end)

-- Commands
RegisterCommand('vehicle_info', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then
        local plate = GetVehicleNumberPlateText(vehicle)
        local data = vehicleData[plate]
        
        if data then
            local maxFuel = GetVehicleFuelCapacity(vehicle)
            ShowNotification(string.format(
                "🚗 Fuel: %.1f/%.1f | Health: %.1f/1000 | Distance: %.1fkm",
                data.fuel, maxFuel, data.engine_health, data.total_distance / 1000
            ), "info")
        end
    else
        ShowNotification("❌ You must be in a vehicle!", "error")
    end
end, false)

RegisterCommand('vehicle_mods', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then
        ShowModificationMenu(vehicle)
    else
        ShowNotification("❌ You must be in a vehicle!", "error")
    end
end, false)

-- NUI Callbacks
RegisterNUICallback('purchaseModification', function(data, cb)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then
        PurchaseModification(vehicle, data.modType)
    end
    cb('ok')
end)

RegisterNUICallback('closeModificationMenu', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Export functions
exports('GetVehicleData', function(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    return vehicleData[plate]
end)

exports('SetVehicleFuel', function(vehicle, fuel)
    local plate = GetVehicleNumberPlateText(vehicle)
    if vehicleData[plate] then
        vehicleData[plate].fuel = fuel
    end
end)

exports('RepairVehicle', function(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    if vehicleData[plate] then
        vehicleData[plate].engine_health = 1000.0
        vehicleData[plate].body_health = 1000.0
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehicleFixed(vehicle)
    end
end)
