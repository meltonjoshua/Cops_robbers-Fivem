-- Environmental Interactions System
local interactables = {
    -- Doors that can be breached
    doors = {
        {coords = {x = 147.0, y = -1038.0, z = 29.4}, locked = true, health = 100, breached = false, type = "bank"},
        {coords = {x = 255.0, y = 225.0, z = 101.9}, locked = true, health = 100, breached = false, type = "bank"},
        {coords = {x = 425.1, y = -979.5, z = 30.7}, locked = true, health = 100, breached = false, type = "police"},
    },
    
    -- Security cameras
    cameras = {
        {coords = {x = 150.0, y = -1040.0, z = 31.0}, active = true, destroyed = false, viewRange = 20.0},
        {coords = {x = 260.0, y = 220.0, z = 103.0}, active = true, destroyed = false, viewRange = 25.0},
        {coords = {x = 430.0, y = -975.0, z = 32.0}, active = true, destroyed = false, viewRange = 15.0},
    },
    
    -- Hackable terminals
    terminals = {
        {coords = {x = 149.0, y = -1042.0, z = 29.4}, hacked = false, difficulty = 3, type = "bank_security"},
        {coords = {x = 257.0, y = 228.0, z = 101.9}, hacked = false, difficulty = 5, type = "vault_control"},
        {coords = {x = 427.0, y = -977.0, z = 30.7}, hacked = false, difficulty = 2, type = "traffic_lights"},
    },
    
    -- Loot containers
    containers = {
        {coords = {x = 145.0, y = -1035.0, z = 29.4}, looted = false, money = 5000, type = "safe"},
        {coords = {x = 252.0, y = 222.0, z = 101.9}, looted = false, money = 25000, type = "vault"},
        {coords = {x = 1729.2, y = 3307.5, z = 41.2}, looted = false, money = 3000, type = "cash_register"},
    },
    
    -- Cover objects
    cover = {
        {coords = {x = 148.0, y = -1036.0, z = 29.4}, type = "concrete_barrier", health = 200, destroyed = false},
        {coords = {x = 258.0, y = 224.0, z = 101.9}, type = "metal_crate", health = 150, destroyed = false},
        {coords = {x = 429.0, y = -976.0, z = 30.7}, type = "police_car", health = 300, destroyed = false},
    }
}

local hackingInProgress = false
local currentHack = nil

-- Initialize environmental interactions
function InitializeEnvironment()
    CreateThread(function()
        while true do
            if gameActive then
                CheckInteractables()
                UpdateCameras()
                CheckCoverDamage()
            end
            Wait(100)
        end
    end)
end

-- Check for nearby interactables
function CheckInteractables()
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    -- Check doors
    for i, door in ipairs(interactables.doors) do
        local distance = #(playerCoords - vector3(door.coords.x, door.coords.y, door.coords.z))
        
        if distance <= 3.0 then
            if door.locked and not door.breached then
                DrawText3D(door.coords.x, door.coords.y, door.coords.z + 1.0, 
                    "~r~[E]~w~ Breach Door (Health: " .. door.health .. ")")
                
                if IsControlJustPressed(0, 38) then -- E key
                    BreachDoor(i)
                end
            elseif door.breached then
                DrawText3D(door.coords.x, door.coords.y, door.coords.z + 1.0, 
                    "~g~Door Breached~w~")
            end
        end
    end
    
    -- Check terminals
    for i, terminal in ipairs(interactables.terminals) do
        local distance = #(playerCoords - vector3(terminal.coords.x, terminal.coords.y, terminal.coords.z))
        
        if distance <= 2.0 then
            if not terminal.hacked then
                DrawText3D(terminal.coords.x, terminal.coords.y, terminal.coords.z + 1.0, 
                    "~b~[E]~w~ Hack Terminal (Difficulty: " .. terminal.difficulty .. ")")
                
                if IsControlJustPressed(0, 38) and not hackingInProgress then -- E key
                    StartHacking(i)
                end
            else
                DrawText3D(terminal.coords.x, terminal.coords.y, terminal.coords.z + 1.0, 
                    "~g~Terminal Hacked~w~")
            end
        end
    end
    
    -- Check containers
    for i, container in ipairs(interactables.containers) do
        local distance = #(playerCoords - vector3(container.coords.x, container.coords.y, container.coords.z))
        
        if distance <= 2.0 then
            if not container.looted then
                DrawText3D(container.coords.x, container.coords.y, container.coords.z + 1.0, 
                    "~g~[E]~w~ Loot Container ($" .. container.money .. ")")
                
                if IsControlJustPressed(0, 38) then -- E key
                    LootContainer(i)
                end
            else
                DrawText3D(container.coords.x, container.coords.y, container.coords.z + 1.0, 
                    "~r~Already Looted~w~")
            end
        end
    end
    
    -- Check cameras for destruction (robbers only)
    if playerTeam == "robber" then
        for i, camera in ipairs(interactables.cameras) do
            local distance = #(playerCoords - vector3(camera.coords.x, camera.coords.y, camera.coords.z))
            
            if distance <= 5.0 and camera.active and not camera.destroyed then
                DrawText3D(camera.coords.x, camera.coords.y, camera.coords.z + 1.0, 
                    "~r~[E]~w~ Destroy Camera")
                
                if IsControlJustPressed(0, 38) then -- E key
                    DestroyCamera(i)
                end
            end
        end
    end
end

-- Breach door functionality
function BreachDoor(doorIndex)
    local door = interactables.doors[doorIndex]
    if door.breached then return end
    
    ShowNotification("Breaching door... Stay close!", "warning")
    
    -- Breaching animation
    local playerPed = PlayerPedId()
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_HAMMERING", 0, true)
    
    CreateThread(function()
        local breachTime = 5000 -- 5 seconds
        local startTime = GetGameTimer()
        
        while GetGameTimer() - startTime < breachTime do
            local progress = (GetGameTimer() - startTime) / breachTime
            DrawText3D(door.coords.x, door.coords.y, door.coords.z + 1.0, 
                "~y~Breaching... " .. math.floor(progress * 100) .. "%")
            
            -- Check if player moved away
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - vector3(door.coords.x, door.coords.y, door.coords.z))
            
            if distance > 5.0 then
                ClearPedTasksImmediately(playerPed)
                ShowNotification("Breach failed! You moved too far away.", "error")
                return
            end
            
            Wait(0)
        end
        
        -- Breach successful
        ClearPedTasksImmediately(playerPed)
        door.breached = true
        door.locked = false
        
        ShowNotification("Door breached successfully!", "success")
        TriggerServerEvent('cr:doorBreached', doorIndex)
        
        -- Add experience
        if exports.statistics then
            exports.statistics:AddExperience(20, "Door breached!")
        end
        
        -- Alert cops if it's a bank door
        if door.type == "bank" then
            TriggerServerEvent('cr:alertCops', "Bank breach detected!", door.coords)
        end
    end)
end

-- Hacking minigame
function StartHacking(terminalIndex)
    local terminal = interactables.terminals[terminalIndex]
    if terminal.hacked or hackingInProgress then return end
    
    hackingInProgress = true
    currentHack = terminalIndex
    
    ShowNotification("Hacking in progress... Follow the pattern!", "info")
    
    -- Simple pattern matching minigame
    local pattern = {}
    local playerInput = {}
    
    -- Generate random pattern based on difficulty
    for i = 1, terminal.difficulty do
        pattern[i] = math.random(1, 4) -- 1-4 for arrow keys
    end
    
    -- Show hacking UI
    SendNUIMessage({
        type = "startHacking",
        pattern = pattern,
        difficulty = terminal.difficulty
    })
    
    SetNuiFocus(true, true)
end

-- Complete hacking
function CompleteHacking(success)
    SetNuiFocus(false, false)
    hackingInProgress = false
    
    if success and currentHack then
        local terminal = interactables.terminals[currentHack]
        terminal.hacked = true
        
        ShowNotification("Terminal hacked successfully!", "success")
        TriggerServerEvent('cr:terminalHacked', currentHack, terminal.type)
        
        -- Apply hack effects
        ApplyHackEffects(terminal.type)
        
        -- Add experience
        if exports.statistics then
            exports.statistics:AddExperience(terminal.difficulty * 15, "Terminal hacked!")
        end
    else
        ShowNotification("Hacking failed!", "error")
        
        -- Alert cops on failed hack
        if currentHack then
            local terminal = interactables.terminals[currentHack]
            TriggerServerEvent('cr:alertCops', "Hacking attempt detected!", terminal.coords)
        end
    end
    
    currentHack = nil
end

-- Apply effects of successful hacks
function ApplyHackEffects(hackType)
    if hackType == "bank_security" then
        -- Disable nearby cameras temporarily
        for _, camera in ipairs(interactables.cameras) do
            camera.active = false
        end
        
        ShowNotification("Security cameras disabled for 60 seconds!", "success")
        
        CreateThread(function()
            Wait(60000) -- 60 seconds
            for _, camera in ipairs(interactables.cameras) do
                if not camera.destroyed then
                    camera.active = true
                end
            end
            ShowNotification("Security cameras reactivated!", "warning")
        end)
        
    elseif hackType == "vault_control" then
        -- Open vault doors
        ShowNotification("Vault doors unlocked!", "success")
        
    elseif hackType == "traffic_lights" then
        -- Cause traffic chaos (visual effect)
        ShowNotification("Traffic lights disrupted! Chaos ensues.", "success")
    end
end

-- Loot container
function LootContainer(containerIndex)
    local container = interactables.containers[containerIndex]
    if container.looted then return end
    
    ShowNotification("Looting container...", "info")
    
    -- Looting animation
    local playerPed = PlayerPedId()
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_CLIPBOARD", 0, true)
    
    CreateThread(function()
        Wait(3000) -- 3 seconds
        
        ClearPedTasksImmediately(playerPed)
        container.looted = true
        
        ShowNotification("Looted $" .. container.money .. "!", "success")
        TriggerServerEvent('cr:containerLooted', containerIndex, container.money)
        
        -- Record money stolen
        if exports.statistics and playerTeam == "robber" then
            exports.statistics:RecordMoneyStolen(container.money)
        end
    end)
end

-- Destroy security camera
function DestroyCamera(cameraIndex)
    local camera = interactables.cameras[cameraIndex]
    if camera.destroyed then return end
    
    ShowNotification("Destroying camera...", "warning")
    
    CreateThread(function()
        Wait(2000) -- 2 seconds
        
        camera.destroyed = true
        camera.active = false
        
        ShowNotification("Camera destroyed!", "success")
        TriggerServerEvent('cr:cameraDestroyed', cameraIndex)
        
        -- Add experience
        if exports.statistics then
            exports.statistics:AddExperience(10, "Camera destroyed!")
        end
        
        -- Create sparks effect
        RequestNamedPtfxAsset("scr_familyscenem")
        while not HasNamedPtfxAssetLoaded("scr_familyscenem") do
            Wait(1)
        end
        
        UseParticleFxAssetNextCall("scr_familyscenem")
        StartParticleFxLoopedAtCoord("scr_meth_pipe_smoke", 
            camera.coords.x, camera.coords.y, camera.coords.z, 
            0.0, 0.0, 0.0, 1.0, false, false, false, false)
    end)
end

-- Update camera surveillance
function UpdateCameras()
    if playerTeam == "robber" then
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for _, camera in ipairs(interactables.cameras) do
            if camera.active and not camera.destroyed then
                local distance = #(playerCoords - vector3(camera.coords.x, camera.coords.y, camera.coords.z))
                
                if distance <= camera.viewRange then
                    -- Player is in camera view
                    if math.random() < 0.1 then -- 10% chance per second to alert
                        TriggerServerEvent('cr:alertCops', "Suspect spotted on camera!", playerCoords)
                        ShowNotification("⚠️ You've been spotted by a security camera!", "warning")
                    end
                end
            end
        end
    end
end

-- Check cover damage
function CheckCoverDamage()
    -- This would integrate with weapon damage system
    -- For now, it's a placeholder for future implementation
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

-- NUI Callbacks
RegisterNUICallback('hackingComplete', function(data, cb)
    CompleteHacking(data.success)
    cb('ok')
end)

-- Initialize on script start
CreateThread(function()
    InitializeEnvironment()
end)

-- Export functions
exports('BreachDoor', BreachDoor)
exports('StartHacking', StartHacking)
exports('LootContainer', LootContainer)
exports('DestroyCamera', DestroyCamera)
