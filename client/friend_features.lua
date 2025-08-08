-- Friend Features - Simple improvements for playing with friends
local friendFeatures = {
    chaseEffects = false,
    quickSpawnCooldown = 0
}

-- Fun taunt system
local taunts = {
    cop = {
        "Stop in the name of the law!",
        "You can't run forever!",
        "Give up now and nobody gets hurt!",
        "I've got you in my sights!",
        "Justice is coming for you!"
    },
    robber = {
        "You'll never catch me alive!",
        "Is that the best you can do?",
        "Too slow, copper!",
        "Catch me if you can!",
        "Freedom or death!"
    }
}

-- Quick vehicle spawning
RegisterCommand('quickcar', function(source, args)
    local currentTime = GetGameTimer()
    
    if currentTime - friendFeatures.quickSpawnCooldown < 30000 then
        ShowNotification("❌ Wait " .. math.ceil((30000 - (currentTime - friendFeatures.quickSpawnCooldown)) / 1000) .. " seconds", "error")
        return
    end
    
    local vehicles = {
        -- Fast cars for robbers
        'adder', 'zentorno', 'bullet', 'cheetah', 'entityxf', 'osiris', 'turismor',
        -- Police vehicles
        'police', 'police2', 'sheriff', 'fbi', 'policeb'
    }
    
    local carType = args[1]
    local selectedVehicle
    
    if carType == "fast" then
        local fastCars = {'adder', 'zentorno', 'bullet', 'cheetah', 'entityxf'}
        selectedVehicle = fastCars[math.random(#fastCars)]
    elseif carType == "cop" then
        local copCars = {'police', 'police2', 'sheriff', 'fbi'}
        selectedVehicle = copCars[math.random(#copCars)]
    else
        selectedVehicle = vehicles[math.random(#vehicles)]
    end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    RequestModel(GetHashKey(selectedVehicle))
    while not HasModelLoaded(GetHashKey(selectedVehicle)) do
        Wait(1)
    end
    
    local vehicle = CreateVehicle(GetHashKey(selectedVehicle), coords.x + 3, coords.y, coords.z, heading, true, false)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleFuelLevel(vehicle, 100.0)
    SetVehicleDirtLevel(vehicle, 0.0)
    
    -- Add some fun modifications
    SetVehicleModKit(vehicle, 0)
    SetVehicleMod(vehicle, 11, 3, false) -- Engine
    SetVehicleMod(vehicle, 12, 2, false) -- Brakes
    SetVehicleMod(vehicle, 13, 2, false) -- Transmission
    SetVehicleMod(vehicle, 15, 3, false) -- Suspension
    
    friendFeatures.quickSpawnCooldown = currentTime
    ShowNotification("🚗 Spawned: " .. selectedVehicle, "success")
end, false)

-- Taunt command
RegisterCommand('taunt', function()
    local playerTeam = playerTeam or "robber" -- Default to robber
    local teamTaunts = taunts[playerTeam] or taunts.robber
    local randomTaunt = teamTaunts[math.random(#teamTaunts)]
    
    -- Send taunt to nearby players
    TriggerServerEvent('cr:sendTaunt', randomTaunt)
    
    -- Play taunt animation
    local playerPed = PlayerPedId()
    RequestAnimDict("mp_player_intupperdefiant")
    while not HasAnimDictLoaded("mp_player_intupperdefiant") do
        Wait(1)
    end
    TaskPlayAnim(playerPed, "mp_player_intupperdefiant", "idle_a", 8.0, -8.0, 2000, 0, 0, false, false, false)
end, false)

-- Quick team switch for balancing
RegisterCommand('switchteam', function()
    TriggerServerEvent('cr:requestTeamSwitch')
end, false)

-- Enhanced arrest with fun effects
RegisterCommand('arrest', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- Find closest player
    local closestPlayer = nil
    local closestDistance = 999.0
    
    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(coords - targetCoords)
            
            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = playerId
            end
        end
    end
    
    if closestPlayer and closestDistance <= 3.0 then
        local targetPed = GetPlayerPed(closestPlayer)
        
        -- Play arrest animation
        RequestAnimDict("mp_arrest_paired")
        while not HasAnimDictLoaded("mp_arrest_paired") do
            Wait(1)
        end
        
        TaskPlayAnim(playerPed, "mp_arrest_paired", "cop_p2_back_left", 8.0, -8.0, 3000, 2, 0, false, false, false)
        TaskPlayAnim(targetPed, "mp_arrest_paired", "crook_p2_back_left", 8.0, -8.0, 3000, 2, 0, false, false, false)
        
        -- Fun arrest effects
        CreateThread(function()
            Wait(1000)
            
            -- Screen flash
            SetFlash(0, 0, 500, 300, 100)
            
            -- Sound effect
            PlaySoundFrontend(-1, "HANDCUFFS", "HEIST_PRISON_BREAK_SOUNDS", true)
            
            -- Notification
            ShowNotification("👮 BUSTED! Player arrested!", "success")
            
            -- Server event
            TriggerServerEvent('cr:arrestPlayer', GetPlayerServerId(closestPlayer))
        end)
    else
        ShowNotification("❌ No one close enough to arrest!", "error")
    end
end, false)

-- Chase effects for high-speed pursuits
function EnableChaseEffects()
    friendFeatures.chaseEffects = true
    
    CreateThread(function()
        while friendFeatures.chaseEffects do
            local playerPed = PlayerPedId()
            
            if IsPedInAnyVehicle(playerPed, false) then
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                local speed = GetEntitySpeed(vehicle) * 3.6 -- Convert to km/h
                
                if speed > 80 then
                    -- Screen shake for intensity
                    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.05)
                    
                    -- Tire smoke effects
                    if speed > 120 then
                        local coords = GetEntityCoords(vehicle)
                        local rotation = GetEntityRotation(vehicle)
                        
                        -- Smoke behind vehicle
                        CreateThread(function()
                            RequestNamedPtfxAsset("core")
                            while not HasNamedPtfxAssetLoaded("core") do
                                Wait(1)
                            end
                            
                            SetPtfxAssetNextCall("core")
                            StartParticleFxLoopedAtCoord("ent_sht_steam", coords.x, coords.y - 2, coords.z, rotation.x, rotation.y, rotation.z, 0.3, false, false, false, false)
                        end)
                    end
                end
            end
            
            Wait(500)
        end
    end)
end

-- Quick restart vote system
local restartVotes = {}
RegisterCommand('restart', function()
    TriggerServerEvent('cr:voteRestart')
end, false)

-- Unstuck command
RegisterCommand('unstuck', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- Try to find a safe ground position
    local safeCoords = GetSafeCoordForPed(coords.x, coords.y, coords.z + 5.0, false, 16)
    
    if safeCoords then
        SetEntityCoords(playerPed, safeCoords.x, safeCoords.y, safeCoords.z)
    else
        SetEntityCoords(playerPed, coords.x, coords.y, coords.z + 5.0)
    end
    
    ShowNotification("✅ You've been unstuck!", "success")
end, false)

-- Fun horn spam
RegisterCommand('hornspam', function()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        CreateThread(function()
            for i = 1, 5 do
                StartVehicleHorn(vehicle, 300, GetHashKey("HELDDOWN"), false)
                Wait(200)
            end
        end)
        
        ShowNotification("📯 Horn spam activated!", "info")
    else
        ShowNotification("❌ You need to be in a vehicle!", "error")
    end
end, false)

-- Show current score
RegisterCommand('score', function()
    TriggerServerEvent('cr:requestScore')
end, false)

-- Event handlers
RegisterNetEvent('cr:receiveScore')
AddEventHandler('cr:receiveScore', function(scoreData)
    local message = string.format("🏆 Your Score:\nArrests: %d | Escapes: %d | Money: $%d", 
        scoreData.arrests or 0, 
        scoreData.escapes or 0, 
        scoreData.money or 0)
    ShowNotification(message, "info")
end)

RegisterNetEvent('cr:receiveTaunt')
AddEventHandler('cr:receiveTaunt', function(playerName, message)
    ShowNotification("💬 " .. playerName .. ": " .. message, "warning")
end)

RegisterNetEvent('cr:teamSwitched')
AddEventHandler('cr:teamSwitched', function(newTeam)
    playerTeam = newTeam
    ShowNotification("🔄 You are now on team: " .. newTeam, "info")
end)

RegisterNetEvent('cr:startChaseMode')
AddEventHandler('cr:startChaseMode', function()
    EnableChaseEffects()
    ShowNotification("🚗💨 Chase mode activated!", "success")
end)

RegisterNetEvent('cr:stopChaseMode')
AddEventHandler('cr:stopChaseMode', function()
    friendFeatures.chaseEffects = false
    ShowNotification("⏹️ Chase mode disabled", "info")
end)

-- Initialize
CreateThread(function()
    Wait(2000)
    
    -- Register keybinds
    RegisterKeyMapping('taunt', 'Send Taunt Message', 'keyboard', 'Y')
    RegisterKeyMapping('quickcar', 'Spawn Quick Vehicle', 'keyboard', 'V')
    RegisterKeyMapping('arrest', 'Arrest Player', 'keyboard', 'E')
    RegisterKeyMapping('score', 'Show Current Score', 'keyboard', 'O')
    RegisterKeyMapping('hornspam', 'Fun Horn Spam', 'keyboard', 'B')
    RegisterKeyMapping('unstuck', 'Get Unstuck', 'keyboard', 'U')
    
    ShowNotification("🎮 Friend features loaded! Press Y to taunt, V for quick car", "success")
end)
