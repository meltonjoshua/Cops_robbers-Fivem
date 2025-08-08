local gameActive = false
local playerTeam = nil
local gameTimer = 0
local arrestTarget = nil
local arrestStartTime = 0
local isArresting = false
local isArrested = false

-- UI Management
local function ShowNotification(message, type)
    type = type or "info"
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostMessagetext("CHAR_DEFAULT", "CHAR_DEFAULT", false, 4, "Cops & Robbers", "")
end

local function DisplayHelpText(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

-- Team Assignment
RegisterNetEvent('cr:assignTeam')
AddEventHandler('cr:assignTeam', function(team)
    playerTeam = team
    gameActive = true
    isArrested = false
    
    if team == "cop" then
        ShowNotification(Config.Messages.joinedAsCop, "success")
        SpawnAsCop()
    elseif team == "robber" then
        ShowNotification(Config.Messages.joinedAsRobber, "info")
        SpawnAsRobber()
    end
    
    -- Enable blips
    TriggerEvent('cr:enableBlips')
end)

-- Spawn Functions
function SpawnAsCop()
    local spawnPoint = Config.CopSpawns[math.random(#Config.CopSpawns)]
    local vehicle = Config.CopVehicles[math.random(#Config.CopVehicles)]
    
    RequestModel(GetHashKey(vehicle))
    while not HasModelLoaded(GetHashKey(vehicle)) do
        Wait(1)
    end
    
    -- Teleport player
    SetEntityCoords(PlayerPedId(), spawnPoint.x, spawnPoint.y, spawnPoint.z)
    SetEntityHeading(PlayerPedId(), spawnPoint.heading)
    
    -- Spawn vehicle
    local veh = CreateVehicle(GetHashKey(vehicle), spawnPoint.x + 2, spawnPoint.y, spawnPoint.z, spawnPoint.heading, true, false)
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
    
    -- Give weapons
    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_STUNGUN"), 1, false, true)
    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_PISTOL"), 150, false, false)
    
    SetModelAsNoLongerNeeded(GetHashKey(vehicle))
end

function SpawnAsRobber()
    local spawnPoint = Config.RobberSpawns[math.random(#Config.RobberSpawns)]
    local vehicle = Config.RobberVehicles[math.random(#Config.RobberVehicles)]
    
    RequestModel(GetHashKey(vehicle))
    while not HasModelLoaded(GetHashKey(vehicle)) do
        Wait(1)
    end
    
    -- Teleport player
    SetEntityCoords(PlayerPedId(), spawnPoint.x, spawnPoint.y, spawnPoint.z)
    SetEntityHeading(PlayerPedId(), spawnPoint.heading)
    
    -- Spawn vehicle
    local veh = CreateVehicle(GetHashKey(vehicle), spawnPoint.x + 2, spawnPoint.y, spawnPoint.z, spawnPoint.heading, true, false)
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
    
    SetModelAsNoLongerNeeded(GetHashKey(vehicle))
end

-- Game Events
RegisterNetEvent('cr:gameStarted')
AddEventHandler('cr:gameStarted', function()
    gameActive = true
    ShowNotification(Config.Messages.gameStarted, "info")
    SendNUIMessage({
        type = "showUI",
        team = playerTeam,
        timer = Config.GameDuration
    })
end)

RegisterNetEvent('cr:gameEnded')
AddEventHandler('cr:gameEnded', function(winner, message)
    gameActive = false
    ShowNotification(message, winner == "cops" and "success" or "error")
    SendNUIMessage({
        type = "hideUI"
    })
end)

RegisterNetEvent('cr:updateGameTimer')
AddEventHandler('cr:updateGameTimer', function(timeLeft)
    gameTimer = timeLeft
    SendNUIMessage({
        type = "updateTimer",
        timer = timeLeft
    })
end)

RegisterNetEvent('cr:cleanup')
AddEventHandler('cr:cleanup', function()
    gameActive = false
    playerTeam = nil
    isArrested = false
    arrestTarget = nil
    isArresting = false
    TriggerEvent('cr:disableBlips')
end)

-- Arrest System
RegisterNetEvent('cr:arrested')
AddEventHandler('cr:arrested', function()
    isArrested = true
    ShowNotification(Config.Messages.arrested, "error")
    
    -- Freeze player
    FreezeEntityPosition(PlayerPedId(), true)
    
    -- Create arrest animation
    RequestAnimDict("mp_arresting")
    while not HasAnimDictLoaded("mp_arresting") do
        Wait(1)
    end
    TaskPlayAnim(PlayerPedId(), "mp_arresting", "idle", 8.0, -8, -1, 49, 0, 0, 0, 0)
    
    -- Teleport to prison after 5 seconds
    Wait(5000)
    SetEntityCoords(PlayerPedId(), 1641.6, 2570.1, 45.6) -- Prison location
    FreezeEntityPosition(PlayerPedId(), false)
    ClearPedTasks(PlayerPedId())
end)

RegisterNetEvent('cr:arrestedSomeone')
AddEventHandler('cr:arrestedSomeone', function(targetName)
    ShowNotification(Config.Messages.arrestedSomeone .. " " .. targetName, "success")
end)

-- Position Updates
CreateThread(function()
    while true do
        if gameActive and playerTeam then
            local coords = GetEntityCoords(PlayerPedId())
            TriggerServerEvent('cr:updatePosition', coords)
        end
        Wait(1000) -- Update every second
    end
end)

-- Arrest Logic
CreateThread(function()
    while true do
        if gameActive and playerTeam == "cop" and not isArrested then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            for _, player in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(player)
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(playerCoords - targetCoords)
                
                if distance <= Config.ArrestDistance and player ~= PlayerId() then
                    local targetId = GetPlayerServerId(player)
                    
                    -- Check if target is a robber (this would need server verification in real implementation)
                    DrawText3D(targetCoords.x, targetCoords.y, targetCoords.z + 1.0, "Press E to arrest")
                    
                    if IsControlJustPressed(0, 38) then -- E key
                        if not isArresting then
                            arrestTarget = targetId
                            arrestStartTime = GetGameTimer()
                            isArresting = true
                            ShowNotification(Config.Messages.arrestInProgress, "info")
                        end
                    end
                end
            end
            
            -- Handle arrest progress
            if isArresting and arrestTarget then
                local currentTime = GetGameTimer()
                local arrestProgress = (currentTime - arrestStartTime) / Config.ArrestTime
                
                if arrestProgress >= 1.0 then
                    -- Arrest completed
                    TriggerServerEvent('cr:requestArrest', arrestTarget)
                    isArresting = false
                    arrestTarget = nil
                else
                    -- Show progress
                    DisplayHelpText("Arresting... " .. math.floor(arrestProgress * 100) .. "%")
                    
                    -- Cancel if moved too far
                    local targetPed = GetPlayerPed(GetPlayerFromServerId(arrestTarget))
                    if targetPed == 0 or #(GetEntityCoords(playerPed) - GetEntityCoords(targetPed)) > Config.ArrestDistance then
                        isArresting = false
                        arrestTarget = nil
                        ShowNotification("Arrest cancelled - target moved away", "error")
                    end
                end
            end
        end
        Wait(0)
    end
end)

-- Notifications
RegisterNetEvent('cr:notify')
AddEventHandler('cr:notify', function(message, type)
    ShowNotification(message, type)
end)

-- Commands
RegisterCommand('startcopsrobbers', function()
    TriggerServerEvent('cr:requestGameStart')
end, false)

RegisterCommand('startcr', function()
    TriggerServerEvent('cr:requestGameStart')
end, false)

-- Chat suggestions
TriggerEvent('chat:addSuggestion', '/startcopsrobbers', 'Start a new Cops and Robbers game')
TriggerEvent('chat:addSuggestion', '/startcr', 'Start a new Cops and Robbers game (short version)')

-- NUI Callbacks
RegisterNUICallback('uiReady', function(data, cb)
    cb('ok')
end)

RegisterNUICallback('closeUI', function(data, cb)
    -- Handle UI close if needed
    cb('ok')
end)

-- Resource cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Clean up when resource stops
        if gameActive then
            TriggerEvent('cr:cleanup')
        end
        SendNUIMessage({
            type = "hideUI"
        })
    end
end)
