-- Keybind System for Cops and Robbers
local uiVisible = true

-- Register keybinds
CreateThread(function()
    Wait(1000) -- Wait for game to load
    
    -- Register keybinds using config
    RegisterKeyMapping('startcr', 'Start Cops and Robbers Game', 'keyboard', Config.Keybinds.startGame)
    RegisterKeyMapping('endcr', 'End Cops and Robbers Game', 'keyboard', Config.Keybinds.endGame)
    RegisterKeyMapping('crgameinfo', 'Show Cops and Robbers Game Info', 'keyboard', Config.Keybinds.gameInfo)
    RegisterKeyMapping('togglecrui', 'Toggle Cops and Robbers UI', 'keyboard', Config.Keybinds.toggleUI)
    RegisterKeyMapping('crhelp', 'Show Cops and Robbers Help', 'keyboard', Config.Keybinds.help)
    
    -- Show keybind notification
    ShowNotification("Cops & Robbers keybinds loaded! Press " .. Config.Keybinds.help .. " for help.", "info")
end)

-- Toggle UI command
RegisterCommand('togglecrui', function()
    if gameActive then
        uiVisible = not uiVisible
        SendNUIMessage({
            type = uiVisible and "showUI" or "hideUI",
            team = playerTeam,
            timer = gameTimer
        })
        ShowNotification("UI " .. (uiVisible and "shown" or "hidden"), "info")
    else
        ShowNotification("No active game to toggle UI for", "error")
    end
end, false)

-- Help command
RegisterCommand('crhelp', function()
    ShowKeybindHelp()
end, false)

-- Show keybind help
function ShowKeybindHelp()
    local helpText = string.format([[
Cops & Robbers - Keybinds

%s - Show this help
%s - Toggle game UI
%s - Start new game
%s - End game (Admin only)
%s - Show game info

Gameplay Controls:
%s - Arrest robber (as cop)
%s - Enter/exit vehicle
ESC - Cancel character selection

Commands:
/startcr or /startcopsrobbers
/endcr (Admin)
/crhelp
/togglecrui
]], 
    Config.Keybinds.help,
    Config.Keybinds.toggleUI,
    Config.Keybinds.startGame,
    Config.Keybinds.endGame,
    Config.Keybinds.gameInfo,
    Config.Keybinds.arrest,
    Config.Keybinds.enterVehicle
    )
    
    -- Show help in NUI
    SendNUIMessage({
        type = "showHelp",
        text = helpText
    })
    
    -- Also show in chat for backup
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 136},
        multiline = true,
        args = {"Cops & Robbers", "Press " .. Config.Keybinds.help .. " for keybinds. Check your screen for the help overlay."}
    })
end

-- Enhanced notification system with keybind hints
function ShowNotificationWithKeybind(message, keybind, type)
    local fullMessage = message
    if keybind then
        fullMessage = message .. " (Press " .. keybind .. ")"
    end
    ShowNotification(fullMessage, type)
end

-- Keybind status display
function ShowKeybindStatus()
    local statusText = string.format([[
Cops & Robbers - Status

Game Active: %s
Your Team: %s
UI Visible: %s

Press %s for help
]], 
        gameActive and "Yes" or "No",
        playerTeam or "None",
        uiVisible and "Yes" or "No",
        Config.Keybinds.help
    )
    
    ShowNotification(statusText, "info")
end

-- Override existing commands to show keybind hints
local originalStartCommand = function() TriggerServerEvent('cr:requestGameStart') end
RegisterCommand('startcr', function()
    originalStartCommand()
    ShowNotificationWithKeybind("Game start requested", Config.Keybinds.startGame, "info")
end, false)

RegisterCommand('startcopsrobbers', function()
    originalStartCommand()
    ShowNotificationWithKeybind("Game start requested", Config.Keybinds.startGame, "info")
end, false)

-- Admin-only end game with keybind hint
RegisterCommand('endcr', function()
    TriggerServerEvent('cr:requestGameEnd')
    ShowNotificationWithKeybind("Game end requested", Config.Keybinds.endGame, "info")
end, true)

-- Game info with keybind hint
RegisterCommand('crgameinfo', function()
    ShowKeybindStatus()
end, false)

-- Arrest keybind enhancement
CreateThread(function()
    while true do
        if gameActive and playerTeam == "cop" and not isArrested then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            -- Check for nearby robbers
            for _, player in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(player)
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(playerCoords - targetCoords)
                
                if distance <= Config.ArrestDistance and player ~= PlayerId() then
                    -- Show enhanced arrest prompt with keybind
                    DrawText3D(targetCoords.x, targetCoords.y, targetCoords.z + 1.2, "~g~[" .. Config.Keybinds.arrest .. "]~w~ Arrest Robber")
                    
                    -- Show help text at bottom of screen
                    DisplayHelpText("Press ~INPUT_CONTEXT~ to arrest the robber")
                    break
                end
            end
        end
        Wait(0)
    end
end)

-- Vehicle entry keybind enhancement
CreateThread(function()
    while true do
        if gameActive then
            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            
            if vehicle == 0 then
                -- Player is not in a vehicle, check for nearby vehicles
                local playerCoords = GetEntityCoords(playerPed)
                local nearbyVehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 5.0, 0, 71)
                
                if nearbyVehicle ~= 0 and DoesEntityExist(nearbyVehicle) then
                    local vehicleCoords = GetEntityCoords(nearbyVehicle)
                    local distance = #(playerCoords - vehicleCoords)
                    
                    if distance <= 5.0 then
                        DisplayHelpText("Press ~INPUT_ENTER~ to enter vehicle")
                    end
                end
            else
                -- Player is in a vehicle
                DisplayHelpText("Press ~INPUT_VEH_EXIT~ to exit vehicle")
            end
        end
        Wait(100) -- Less frequent updates for performance
    end
end)

-- Character selection keybind hints
RegisterNetEvent('cr:startCharacterSelection')
AddEventHandler('cr:startCharacterSelection', function(teams)
    -- Show keybind hints for character selection
    ShowNotification("Character Selection Started!\nUse mouse to select, Enter to confirm, ESC to cancel", "info")
end)

-- Enhanced game start notification with keybinds
RegisterNetEvent('cr:gameStarted')
AddEventHandler('cr:gameStarted', function()
    local keybindHint = string.format("Game Started! %s: Toggle UI | %s: End Game | %s: Info", 
        Config.Keybinds.toggleUI, Config.Keybinds.endGame, Config.Keybinds.gameInfo)
    ShowNotification(keybindHint, "success")
end)

-- Add keybind suggestions to chat on resource start
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Wait(5000) -- Wait 5 seconds after resource start
        TriggerEvent('chat:addSuggestion', '/crhelp', 'Show Cops and Robbers help and keybinds')
        TriggerEvent('chat:addSuggestion', '/togglecrui', 'Toggle the game UI on/off')
        
        -- Show welcome message with keybinds
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 136},
            args = {"Cops & Robbers", "Keybinds loaded! Press " .. Config.Keybinds.help .. " for help, " .. Config.Keybinds.startGame .. " to start game"}
        })
    end
end)
