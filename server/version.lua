-- Version and Update System
local SCRIPT_VERSION = "1.0.0"
local SCRIPT_NAME = "Cops & Robbers"
local GITHUB_REPO = "meltonjoshua/Cops_robbers-Fivem"

-- Version check (server-side)
CreateThread(function()
    local resourceName = GetCurrentResourceName()
    print("^2[" .. SCRIPT_NAME .. "]^7 Version " .. SCRIPT_VERSION .. " loaded successfully!")
    print("^2[" .. SCRIPT_NAME .. "]^7 Resource: " .. resourceName)
    
    -- Basic startup validation
    local validationPassed = true
    
    -- Check if config exists
    if not Config then
        print("^1[" .. SCRIPT_NAME .. "] ERROR: Config not loaded!^7")
        validationPassed = false
    end
    
    -- Check spawn points
    if Config and (#Config.CopSpawns == 0 or #Config.RobberSpawns == 0) then
        print("^3[" .. SCRIPT_NAME .. "] WARNING: No spawn points configured!^7")
    end
    
    -- Check vehicles
    if Config and (#Config.CopVehicles == 0 or #Config.RobberVehicles == 0) then
        print("^3[" .. SCRIPT_NAME .. "] WARNING: No vehicles configured!^7")
    end
    
    if validationPassed then
        print("^2[" .. SCRIPT_NAME .. "]^7 Validation passed - ready for use!")
        print("^2[" .. SCRIPT_NAME .. "]^7 Use '/startcr' or '/startcopsrobbers' to begin a game")
    else
        print("^1[" .. SCRIPT_NAME .. "] Critical errors found - resource may not work properly!^7")
    end
end)

-- Debug command for admins
RegisterCommand('cr:debug', function(source, args, rawCommand)
    if source == 0 or IsPlayerAceAllowed(source, "command.admin") then
        local debugInfo = {
            version = SCRIPT_VERSION,
            gameActive = gameActive,
            playerCount = GetNumPlayerIndices(),
            cops = cops,
            robbers = robbers,
            arrested = arrestedRobbers,
            timeLeft = gameActive and math.max(0, math.floor((gameEndTime - GetGameTimer()) / 1000)) or 0,
            configLoaded = Config ~= nil
        }
        
        if source == 0 then
            print("=== " .. SCRIPT_NAME .. " Debug Info ===")
            print("Version: " .. debugInfo.version)
            print("Game Active: " .. tostring(debugInfo.gameActive))
            print("Player Count: " .. debugInfo.playerCount)
            print("Config Loaded: " .. tostring(debugInfo.configLoaded))
            if debugInfo.gameActive then
                print("Time Left: " .. debugInfo.timeLeft .. " seconds")
                print("Cops: " .. json.encode(debugInfo.cops))
                print("Robbers: " .. json.encode(debugInfo.robbers))
                print("Arrested: " .. json.encode(debugInfo.arrested))
            end
            print("================================")
        else
            TriggerClientEvent('cr:notify', source, "Debug info printed to server console")
        end
    else
        TriggerClientEvent('cr:notify', source, "Access denied - admin only")
    end
end, true)

-- Performance monitoring
local performanceStats = {
    startTime = GetGameTimer(),
    gamesPlayed = 0,
    totalArrests = 0,
    averageGameDuration = 0
}

-- Update performance stats
function UpdatePerformanceStats(gameEndReason, actualDuration)
    performanceStats.gamesPlayed = performanceStats.gamesPlayed + 1
    
    if gameEndReason == "arrest" then
        performanceStats.totalArrests = performanceStats.totalArrests + 1
    end
    
    -- Calculate average game duration
    if performanceStats.gamesPlayed == 1 then
        performanceStats.averageGameDuration = actualDuration
    else
        performanceStats.averageGameDuration = (
            (performanceStats.averageGameDuration * (performanceStats.gamesPlayed - 1)) + actualDuration
        ) / performanceStats.gamesPlayed
    end
end

-- Performance stats command
RegisterCommand('cr:stats', function(source, args, rawCommand)
    if source == 0 or IsPlayerAceAllowed(source, "command.admin") then
        local uptime = (GetGameTimer() - performanceStats.startTime) / 1000
        local uptimeHours = math.floor(uptime / 3600)
        local uptimeMinutes = math.floor((uptime % 3600) / 60)
        
        local stats = string.format([[
=== %s Performance Stats ===
Uptime: %dh %dm
Games Played: %d
Total Arrests: %d
Average Game Duration: %.1f minutes
Current Players: %d
============================]], 
            SCRIPT_NAME,
            uptimeHours, uptimeMinutes,
            performanceStats.gamesPlayed,
            performanceStats.totalArrests,
            performanceStats.averageGameDuration / 60,
            GetNumPlayerIndices()
        )
        
        if source == 0 then
            print(stats)
        else
            TriggerClientEvent('cr:notify', source, "Performance stats printed to console")
        end
    end
end, true)
