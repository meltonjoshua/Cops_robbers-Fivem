-- Enhanced Keybinds System
local keybindsActive = true
local helpOverlayVisible = false

-- Register all keybinds
function RegisterAllKeybinds()
    -- F5 - Toggle Help/Keybinds overlay
    RegisterKeyMapping('cr_help', 'Show Cops & Robbers Help', 'keyboard', 'F5')
    RegisterCommand('cr_help', function()
        ToggleHelpOverlay()
    end, false)
    
    -- F6 - Toggle Game UI
    RegisterKeyMapping('cr_toggle_ui', 'Toggle Game UI', 'keyboard', 'F6')
    RegisterCommand('cr_toggle_ui', function()
        ToggleGameUI()
    end, false)
    
    -- F7 - Start Game (if enough players)
    RegisterKeyMapping('cr_start_game', 'Start Cops & Robbers Game', 'keyboard', 'F7')
    RegisterCommand('cr_start_game', function()
        if not gameActive then
            TriggerServerEvent('cr:startGame')
        else
            ShowNotification("Game is already active!", "error")
        end
    end, false)
    
    -- F8 - End Game (admin/vote)
    RegisterKeyMapping('cr_end_game', 'End Cops & Robbers Game', 'keyboard', 'F8')
    RegisterCommand('cr_end_game', function()
        if gameActive then
            TriggerServerEvent('cr:endGame')
        else
            ShowNotification("No game is currently active!", "error")
        end
    end, false)
    
    -- F9 - Game Information
    RegisterKeyMapping('cr_game_info', 'Show Game Information', 'keyboard', 'F9')
    RegisterCommand('cr_game_info', function()
        ShowGameInfo()
    end, false)
    
    -- F10 - Player Statistics
    RegisterKeyMapping('cr_stats', 'Show Player Statistics', 'keyboard', 'F10')
    RegisterCommand('cr_stats', function()
        ShowPlayerStats()
    end, false)
    
    -- F11 - Change Game Mode (if not in game)
    RegisterKeyMapping('cr_change_mode', 'Change Game Mode', 'keyboard', 'F11')
    RegisterCommand('cr_change_mode', function()
        if not gameActive then
            ShowGameModeSelector()
        else
            ShowNotification("Cannot change mode during active game!", "error")
        end
    end, false)
    
    ShowNotification("Keybinds registered! Press F5 for help.", "success")
end

-- Toggle help overlay
function ToggleHelpOverlay()
    helpOverlayVisible = not helpOverlayVisible
    
    if helpOverlayVisible then
        ShowHelpOverlay()
    else
        HideHelpOverlay()
    end
end

-- Show help overlay
function ShowHelpOverlay()
    SendNUIMessage({
        type = "showHelp",
        keybinds = {
            {key = "F5", description = "Toggle this help menu"},
            {key = "F6", description = "Toggle game UI elements"},
            {key = "F7", description = "Start new game (needs " .. Config.MinPlayers .. "+ players)"},
            {key = "F8", description = "End current game"},
            {key = "F9", description = "Show game information & status"},
            {key = "F10", description = "View your statistics & achievements"},
            {key = "F11", description = "Change game mode (when not in game)"},
            {key = "E", description = "Interact with objects/arrest players"},
            {key = "Arrow Keys", description = "Navigate hacking minigames"},
            {key = "Tab", description = "Show player list (during game)"},
            {key = "Escape", description = "Close menus and overlays"}
        },
        gameCommands = {
            {command = "/surrender", description = "Surrender to nearby cops"},
            {command = "/teamchat [message]", description = "Send message to your team"},
            {command = "/gameinfo", description = "Show current game status"},
            {command = "/rules", description = "Show game rules"},
            {command = "/reset_stats", description = "Reset your statistics (admin only)"}
        }
    })
    
    ShowNotification("Help overlay shown. Press F5 again to hide.", "info")
end

-- Hide help overlay
function HideHelpOverlay()
    SendNUIMessage({
        type = "hideHelp"
    })
end

-- Toggle game UI
function ToggleGameUI()
    SendNUIMessage({
        type = "toggleUI"
    })
    
    ShowNotification("Game UI toggled", "info")
end

-- Show game information
function ShowGameInfo()
    local gameStatus = "No active game"
    local timeRemaining = "N/A"
    local playerCount = GetActivePlayers()
    
    if gameActive then
        gameStatus = "Game in progress"
        if gameEndTime then
            local remaining = math.max(0, gameEndTime - GetGameTimer())
            timeRemaining = FormatTime(remaining)
        end
    end
    
    local gameMode = "Classic"
    if exports.game_modes then
        gameMode = exports.game_modes:GetCurrentGameMode() or "Classic"
    end
    
    SendNUIMessage({
        type = "showGameInfo",
        info = {
            status = gameStatus,
            timeRemaining = timeRemaining,
            currentPlayers = #playerCount,
            minPlayers = Config.MinPlayers,
            gameMode = gameMode,
            playerTeam = playerTeam or "None",
            isInGame = gameActive
        }
    })
    
    CreateThread(function()
        Wait(8000) -- Auto-hide after 8 seconds
        SendNUIMessage({
            type = "hideGameInfo"
        })
    end)
end

-- Show player statistics
function ShowPlayerStats()
    if exports.statistics then
        local stats = exports.statistics:GetDisplayStats()
        
        SendNUIMessage({
            type = "showStats",
            stats = stats
        })
    else
        ShowNotification("Statistics system not available!", "error")
    end
end

-- Show game mode selector
function ShowGameModeSelector()
    SendNUIMessage({
        type = "showModeSelector",
        modes = {
            {id = "classic", name = "Classic", description = "Traditional cops vs robbers - survive for 10 minutes"},
            {id = "bank_heist", name = "Bank Heist", description = "Rob banks to collect money and escape"},
            {id = "vip_escort", name = "VIP Escort", description = "Escort the VIP safely or eliminate them"},
            {id = "territory_control", name = "Territory Control", description = "Capture and hold territories to win"},
            {id = "survival", name = "Survival", description = "Survive waves of increasing difficulty"}
        }
    })
end

-- Format time in MM:SS
function FormatTime(ms)
    local totalSeconds = math.floor(ms / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    
    return string.format("%02d:%02d", minutes, seconds)
end

-- Additional commands
RegisterCommand('surrender', function()
    if gameActive and playerTeam == "robber" then
        local nearbyPlayers = GetNearbyPlayers(5.0)
        local copNearby = false
        
        for _, playerId in ipairs(nearbyPlayers) do
            if NetworkGetPlayerIndexFromPed(GetPlayerPed(playerId)) ~= PlayerId() then
                -- Check if this player is a cop (simplified check)
                copNearby = true
                break
            end
        end
        
        if copNearby then
            ShowNotification("You surrendered to the police!", "info")
            TriggerServerEvent('cr:playerSurrendered')
        else
            ShowNotification("No police officers nearby to surrender to!", "error")
        end
    else
        ShowNotification("You can only surrender as a robber during a game!", "error")
    end
end, false)

RegisterCommand('teamchat', function(source, args)
    if gameActive and playerTeam then
        local message = table.concat(args, " ")
        if message ~= "" then
            TriggerServerEvent('cr:teamChat', message)
        else
            ShowNotification("Usage: /teamchat [message]", "info")
        end
    else
        ShowNotification("You must be in a game to use team chat!", "error")
    end
end, false)

RegisterCommand('gameinfo', function()
    ShowGameInfo()
end, false)

RegisterCommand('rules', function()
    SendNUIMessage({
        type = "showRules",
        rules = {
            "1. Cops must arrest robbers within 10 minutes",
            "2. Robbers must evade capture for 10 minutes to win",
            "3. Use E to arrest robbers when close",
            "4. Robbers can resist arrest by following prompts",
            "5. Team chat available with /teamchat [message]",
            "6. No camping in unreachable areas",
            "7. Play fair and have fun!",
            "8. Different game modes have different objectives",
            "9. Earn XP and unlock achievements by playing",
            "10. Use F-keys for quick access to game features"
        }
    })
end, false)

RegisterCommand('reset_stats', function()
    if exports.statistics then
        exports.statistics:ResetStats()
    else
        ShowNotification("Statistics system not available!", "error")
    end
end, false)

-- Get nearby players
function GetNearbyPlayers(radius)
    local players = {}
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local targetPed = GetPlayerPed(player)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)
            
            if distance <= radius then
                table.insert(players, player)
            end
        end
    end
    
    return players
end

-- Initialize keybinds when script starts
CreateThread(function()
    Wait(1000) -- Wait for other systems to load
    RegisterAllKeybinds()
end)

-- NUI Callbacks
RegisterNUICallback('selectGameMode', function(data, cb)
    if not gameActive then
        TriggerServerEvent('cr:changeGameMode', data.mode)
        ShowNotification("Game mode changed to: " .. data.mode, "success")
    end
    cb('ok')
end)

RegisterNUICallback('closeUI', function(data, cb)
    helpOverlayVisible = false
    cb('ok')
end)
