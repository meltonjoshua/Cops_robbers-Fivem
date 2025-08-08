-- Test script for 2-player functionality
-- This script helps test and verify that the game works with just 2 players

-- Debug command to test 2-player setup
RegisterCommand('test2players', function(source, args)
    local players = GetPlayers()
    local playerCount = #players
    
    print("=== 2-Player Test ===")
    print("Current player count: " .. playerCount)
    print("Minimum required: " .. Config.MinPlayers)
    
    if playerCount >= 2 then
        print("✅ Sufficient players for 2-player game")
        
        -- Test team assignment for 2 players
        if playerCount == 2 then
            print("Perfect 2-player setup (1v1)")
            TriggerEvent('cr:startQuickGame', 'classic')
        else
            print("Testing with " .. playerCount .. " players")
            TriggerEvent('cr:startQuickGame', 'classic')
        end
    else
        print("❌ Need at least 2 players (currently have " .. playerCount .. ")")
    end
end, true)

-- Command to simulate 2-player team assignment
RegisterCommand('assign2teams', function(source, args)
    local players = GetPlayers()
    
    if #players >= 2 then
        -- Assign first player as cop, second as robber
        TriggerClientEvent('cr:teamSwitched', players[1], 'cop')
        TriggerClientEvent('cr:teamSwitched', players[2], 'robber')
        
        print("Assigned " .. GetPlayerName(players[1]) .. " as COP")
        print("Assigned " .. GetPlayerName(players[2]) .. " as ROBBER")
        
        TriggerClientEvent('QBCore:Notify', -1, 'Teams assigned for 2-player test!', 'success')
    else
        print("Need at least 2 players for team assignment test")
    end
end, true)

-- Verify configuration
CreateThread(function()
    Wait(1000)
    
    print("^2[Cops & Robbers - 2 Player Test]^7")
    print("Minimum players: " .. Config.MinPlayers)
    print("Game duration: " .. (Config.GameDuration / 1000) .. " seconds")
    
    if Config.MinPlayers <= 2 then
        print("^2✅ Configuration supports 2-player games^7")
    else
        print("^1❌ Configuration requires more than 2 players^7")
    end
    
    print("^3Test commands:^7")
    print("  /test2players - Test 2-player functionality")
    print("  /assign2teams - Manually assign teams for 2 players")
    print("  /quickstart - Start a quick game with current players")
end)
