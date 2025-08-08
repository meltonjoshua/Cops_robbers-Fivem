local arrestAnimDict = "mp_arresting"
local arrestAnim = "a_arrest_cop"
local arrestedAnim = "idle"

-- Initialize arrest system
CreateThread(function()
    -- Preload arrest animations
    RequestAnimDict(arrestAnimDict)
    while not HasAnimDictLoaded(arrestAnimDict) do
        Wait(1)
    end
end)

-- Arrest interaction system
local function GetClosestRobber()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestPlayer = nil
    local closestDistance = Config.ArrestDistance + 1
    
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local targetPed = GetPlayerPed(player)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)
            
            if distance < closestDistance then
                closestPlayer = GetPlayerServerId(player)
                closestDistance = distance
            end
        end
    end
    
    return closestPlayer, closestDistance
end

-- Arrest progress bar (simple text implementation)
local function ShowArrestProgress(progress)
    local barLength = 20
    local filledLength = math.floor(progress * barLength)
    local bar = "["
    
    for i = 1, barLength do
        if i <= filledLength then
            bar = bar .. "="
        else
            bar = bar .. "-"
        end
    end
    
    bar = bar .. "] " .. math.floor(progress * 100) .. "%"
    
    SetTextComponentFormat("STRING")
    AddTextComponentString("~b~Arresting: ~w~" .. bar)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

-- Enhanced arrest system with progress tracking
local arrestInProgress = false
local arrestStartTime = 0
local arrestTargetId = nil

CreateThread(function()
    while true do
        Wait(0)
        
        if gameActive and playerTeam == "cop" and not isArrested then
            local closestRobber, distance = GetClosestRobber()
            
            if closestRobber and distance <= Config.ArrestDistance then
                if not arrestInProgress then
                    -- Show arrest prompt
                    local targetPed = GetPlayerPed(GetPlayerFromServerId(closestRobber))
                    local targetCoords = GetEntityCoords(targetPed)
                    DrawText3D(targetCoords.x, targetCoords.y, targetCoords.z + 1.2, "~g~[E]~w~ Arrest Robber")
                    
                    if IsControlJustPressed(0, 38) then -- E key
                        arrestInProgress = true
                        arrestStartTime = GetGameTimer()
                        arrestTargetId = closestRobber
                        
                        -- Start arrest animation
                        TaskPlayAnim(PlayerPedId(), arrestAnimDict, arrestAnim, 8.0, -8, -1, 1, 0, 0, 0, 0)
                    end
                else
                    -- Arrest in progress
                    if arrestTargetId == closestRobber then
                        local currentTime = GetGameTimer()
                        local progress = math.min((currentTime - arrestStartTime) / Config.ArrestTime, 1.0)
                        
                        ShowArrestProgress(progress)
                        
                        if progress >= 1.0 then
                            -- Arrest completed
                            TriggerServerEvent('cr:requestArrest', arrestTargetId)
                            arrestInProgress = false
                            arrestTargetId = nil
                            ClearPedTasks(PlayerPedId())
                        end
                        
                        -- Cancel arrest if target moves away
                        if distance > Config.ArrestDistance then
                            arrestInProgress = false
                            arrestTargetId = nil
                            ClearPedTasks(PlayerPedId())
                            ShowNotification("Arrest cancelled - target escaped!", "error")
                        end
                    else
                        -- Target changed, cancel arrest
                        arrestInProgress = false
                        arrestTargetId = nil
                        ClearPedTasks(PlayerPedId())
                    end
                end
            else
                -- No target in range, cancel arrest if in progress
                if arrestInProgress then
                    arrestInProgress = false
                    arrestTargetId = nil
                    ClearPedTasks(PlayerPedId())
                end
            end
        else
            -- Not a cop or game not active, cancel any arrest
            if arrestInProgress then
                arrestInProgress = false
                arrestTargetId = nil
                ClearPedTasks(PlayerPedId())
            end
        end
    end
end)

-- Handle being arrested
local function HandleArrest()
    local playerPed = PlayerPedId()
    
    -- Play arrested animation
    RequestAnimDict(arrestAnimDict)
    while not HasAnimDictLoaded(arrestAnimDict) do
        Wait(1)
    end
    
    TaskPlayAnim(playerPed, arrestAnimDict, arrestedAnim, 8.0, -8, -1, 49, 0, 0, 0, 0)
    
    -- Disable controls temporarily
    CreateThread(function()
        local endTime = GetGameTimer() + 3000 -- 3 seconds
        while GetGameTimer() < endTime do
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true) -- Look around
            EnableControlAction(0, 2, true) -- Look around
            Wait(0)
        end
    end)
    
    -- Show arrest notification with effect
    ShowNotification("~r~You have been arrested!", "error")
    
    -- Screen effect
    SetTimecycleModifier("mugshot_character_lighting")
    Wait(2000)
    ClearTimecycleModifier()
    
    -- Transport to prison
    Wait(1000)
    DoScreenFadeOut(1000)
    Wait(1500)
    
    -- Teleport to prison
    SetEntityCoords(playerPed, 1641.6, 2570.1, 45.6, false, false, false, true)
    SetEntityHeading(playerPed, 180.0)
    
    DoScreenFadeIn(1000)
    ClearPedTasks(playerPed)
    
    ShowNotification("You are now in prison. Wait for the game to end.", "info")
end

-- Enhanced arrest event
RegisterNetEvent('cr:arrested')
AddEventHandler('cr:arrested', function()
    isArrested = true
    HandleArrest()
end)

-- Escape system for robbers
CreateThread(function()
    while true do
        if gameActive and playerTeam == "robber" and not isArrested then
            local playerCoords = GetEntityCoords(PlayerPedId())
            
            -- Check if robber is in a "safe zone" (far from cops)
            local safeDist = 500.0 -- 500 meters
            local nearCop = false
            
            for _, player in ipairs(GetActivePlayers()) do
                if player ~= PlayerId() then
                    local targetCoords = GetEntityCoords(GetPlayerPed(player))
                    local distance = #(playerCoords - targetCoords)
                    
                    if distance < safeDist then
                        -- This would need server-side verification for player team
                        -- For now, we assume any nearby player could be a cop
                        nearCop = true
                        break
                    end
                end
            end
            
            if not nearCop then
                -- Show escape notification occasionally
                if math.random(1, 100) == 1 then -- 1% chance per frame when far from cops
                    ShowNotification("~g~You're in a safe area! Keep avoiding the police!", "success")
                end
            end
        end
        Wait(1000)
    end
end)
