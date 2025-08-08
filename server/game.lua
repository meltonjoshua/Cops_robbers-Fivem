-- Game event handlers
RegisterNetEvent('cr:requestGameStart')
AddEventHandler('cr:requestGameStart', function()
    local source = source
    local success, message = StartGame()
    TriggerClientEvent('cr:notify', source, message)
end)

RegisterNetEvent('cr:requestArrest')
AddEventHandler('cr:requestArrest', function(targetId)
    local source = source
    if ArrestRobber(source, targetId) then
        print(string.format("Player %s arrested player %s", GetPlayerName(source), GetPlayerName(targetId)))
    end
end)

RegisterNetEvent('cr:updatePosition')
AddEventHandler('cr:updatePosition', function(coords)
    local source = source
    if gamePlayers[source] then
        gamePlayers[source].position = coords
        TriggerClientEvent('cr:updatePlayerPosition', -1, source, coords, gamePlayers[source].team)
    end
end)

RegisterNetEvent('cr:characterSelected')
AddEventHandler('cr:characterSelected', function(data)
    local source = source
    HandleCharacterSelection(source, data)
end)

-- Commands
RegisterCommand('startcr', function(source, args, rawCommand)
    if source == 0 then -- Console command
        local success, message = StartGame()
        print(message)
    else
        local success, message = StartGame()
        TriggerClientEvent('cr:notify', source, message)
    end
end, false)

RegisterCommand('endcr', function(source, args, rawCommand)
    if source == 0 then -- Console command
        EndGame('admin')
        print("Game ended by admin")
    else
        EndGame('admin')
        TriggerClientEvent('cr:notify', source, "Game ended by admin")
    end
end, true) -- Restricted command

-- Admin commands
RegisterCommand('crgameinfo', function(source, args, rawCommand)
    if source == 0 or IsPlayerAceAllowed(source, "command.admin") then
        local info = {
            active = gameActive,
            cops = cops,
            robbers = robbers,
            arrested = arrestedRobbers,
            timeLeft = gameActive and math.max(0, math.floor((gameEndTime - GetGameTimer()) / 1000)) or 0
        }
        
        if source == 0 then
            print("=== Cops and Robbers Game Info ===")
            print("Game Active: " .. tostring(info.active))
            print("Time Left: " .. info.timeLeft .. " seconds")
            print("Cops: " .. json.encode(info.cops))
            print("Robbers: " .. json.encode(info.robbers))
            print("Arrested: " .. json.encode(info.arrested))
        else
            TriggerClientEvent('cr:notify', source, "Game info printed to server console")
        end
    end
end, true)
