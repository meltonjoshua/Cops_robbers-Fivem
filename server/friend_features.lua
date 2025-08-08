-- Server-side Friend Features
local QBCore = exports['qb-core']:GetCoreObject() or {}

-- Game state for friends
local friendGame = {
    active = false,
    players = {},
    scores = {},
    mode = 'classic',
    startTime = 0,
    restartVotes = {}
}

-- Simple scoring system
function InitializePlayerScore(playerId)
    if not friendGame.scores[playerId] then
        friendGame.scores[playerId] = {
            arrests = 0,
            escapes = 0,
            money = 0,
            kills = 0
        }
    end
end

-- Auto team balancing for small groups
RegisterServerEvent('cr:requestTeamSwitch')
AddEventHandler('cr:requestTeamSwitch', function()
    local src = source
    local players = GetPlayers()
    
    if #players < 2 then
        TriggerClientEvent('QBCore:Notify', src, 'Need at least 2 players for team switch!', 'error')
        return
    end
    
    -- Simple team assignment
    local teams = {'cop', 'robber'}
    local newTeam = teams[math.random(#teams)]
    
    TriggerClientEvent('cr:teamSwitched', src, newTeam)
    TriggerClientEvent('QBCore:Notify', -1, GetPlayerName(src) .. ' switched to ' .. newTeam .. ' team!', 'info')
end)

-- Handle taunts
RegisterServerEvent('cr:sendTaunt')
AddEventHandler('cr:sendTaunt', function(message)
    local src = source
    local playerName = GetPlayerName(src)
    
    -- Send taunt to all players within range (or all players for friends)
    TriggerClientEvent('cr:receiveTaunt', -1, playerName, message)
end)

-- Enhanced arrest system
RegisterServerEvent('cr:arrestPlayer')
AddEventHandler('cr:arrestPlayer', function(targetId)
    local src = source
    local copName = GetPlayerName(src)
    local robberName = GetPlayerName(targetId)
    
    -- Initialize scores
    InitializePlayerScore(src)
    InitializePlayerScore(targetId)
    
    -- Add arrest score
    friendGame.scores[src].arrests = friendGame.scores[src].arrests + 1
    
    -- Teleport arrested player to a "jail" location
    local jailLocations = {
        {x = 1641.93, y = 2570.48, z = 45.56}, -- Prison
        {x = 425.1, y = -979.5, z = 30.7},     -- Mission Row PD
        {x = -1096.8, y = -806.45, z = 19.0}   -- Mirror Park PD
    }
    
    local jailCoord = jailLocations[math.random(#jailLocations)]
    TriggerClientEvent('cr:teleportToJail', targetId, jailCoord)
    
    -- Fun arrest messages
    local arrestMessages = {
        copName .. " just busted " .. robberName .. "!",
        robberName .. " got caught red-handed by " .. copName .. "!",
        "ARREST ALERT: " .. robberName .. " is behind bars thanks to " .. copName .. "!",
        copName .. " brings justice to " .. robberName .. "!",
        robberName .. " couldn't outrun the long arm of the law (" .. copName .. ")!"
    }
    
    TriggerClientEvent('chat:addMessage', -1, {
        color = {255, 165, 0},
        multiline = true,
        args = {"[🚨 BUSTED]", arrestMessages[math.random(#arrestMessages)]}
    })
    
    -- Release after 30 seconds for friends (shorter jail time)
    SetTimeout(30000, function()
        TriggerClientEvent('cr:releaseFromJail', targetId)
        TriggerClientEvent('QBCore:Notify', targetId, 'You have been released from jail!', 'success')
    end)
end)

-- Score request
RegisterServerEvent('cr:requestScore')
AddEventHandler('cr:requestScore', function()
    local src = source
    InitializePlayerScore(src)
    
    TriggerClientEvent('cr:receiveScore', src, friendGame.scores[src])
end)

-- Quick game start for friends
RegisterServerEvent('cr:startQuickGame')
AddEventHandler('cr:startQuickGame', function(mode)
    local src = source
    local players = GetPlayers()
    
    if #players < 2 then
        TriggerClientEvent('QBCore:Notify', src, 'Need at least 2 players to start!', 'error')
        return
    end
    
    friendGame.active = true
    friendGame.mode = mode or 'classic'
    friendGame.startTime = GetGameTimer()
    friendGame.players = players
    
    -- Auto balance teams for friends
    local halfPlayers = math.ceil(#players / 2)
    
    for i, playerId in ipairs(players) do
        local team = i <= halfPlayers and 'cop' or 'robber'
        TriggerClientEvent('cr:teamSwitched', playerId, team)
    end
    
    -- Shorter game duration for friends (5 minutes)
    local gameDuration = 300000 -- 5 minutes
    
    TriggerClientEvent('QBCore:Notify', -1, 'Quick ' .. friendGame.mode .. ' game started! Duration: 5 minutes', 'success')
    TriggerClientEvent('cr:startChaseMode', -1)
    
    -- Auto-end game
    SetTimeout(gameDuration, function()
        if friendGame.active then
            EndQuickGame('Time expired!')
        end
    end)
end)

-- End game function
function EndQuickGame(reason)
    friendGame.active = false
    
    -- Calculate final scores
    local finalScores = {}
    for playerId, score in pairs(friendGame.scores) do
        local playerName = GetPlayerName(playerId)
        if playerName then
            table.insert(finalScores, {
                name = playerName,
                arrests = score.arrests,
                escapes = score.escapes,
                money = score.money,
                total = score.arrests * 10 + score.escapes * 5 + math.floor(score.money / 1000)
            })
        end
    end
    
    -- Sort by total score
    table.sort(finalScores, function(a, b) return a.total > b.total end)
    
    -- Announce results
    TriggerClientEvent('chat:addMessage', -1, {
        color = {0, 255, 255},
        multiline = true,
        args = {"[🏁 GAME END]", reason}
    })
    
    -- Show top 3 players
    for i = 1, math.min(3, #finalScores) do
        local player = finalScores[i]
        local medal = i == 1 and "🥇" or (i == 2 and "🥈" or "🥉")
        
        TriggerClientEvent('chat:addMessage', -1, {
            color = {255, 215, 0},
            multiline = true,
            args = {"[" .. medal .. " PLACE " .. i .. "]", player.name .. " - Score: " .. player.total}
        })
    end
    
    TriggerClientEvent('cr:stopChaseMode', -1)
    
    -- Reset scores for next game
    friendGame.scores = {}
end

-- Restart vote system
RegisterServerEvent('cr:voteRestart')
AddEventHandler('cr:voteRestart', function()
    local src = source
    local playerName = GetPlayerName(src)
    local players = GetPlayers()
    
    if friendGame.restartVotes[src] then
        TriggerClientEvent('QBCore:Notify', src, 'You already voted to restart!', 'error')
        return
    end
    
    friendGame.restartVotes[src] = true
    local voteCount = 0
    
    for _ in pairs(friendGame.restartVotes) do
        voteCount = voteCount + 1
    end
    
    local requiredVotes = math.ceil(#players / 2) -- Need majority
    
    TriggerClientEvent('chat:addMessage', -1, {
        color = {255, 255, 0},
        multiline = true,
        args = {"[🗳️ RESTART VOTE]", playerName .. " voted to restart (" .. voteCount .. "/" .. requiredVotes .. ")"}
    })
    
    if voteCount >= requiredVotes then
        TriggerClientEvent('QBCore:Notify', -1, 'Restart vote passed! Restarting game...', 'success')
        
        -- Reset everything
        friendGame.restartVotes = {}
        if friendGame.active then
            EndQuickGame('Restart vote passed')
        end
        
        -- Auto start new game after 3 seconds
        SetTimeout(3000, function()
            TriggerEvent('cr:startQuickGame', friendGame.mode)
        end)
    end
end)

-- Admin commands for friends
RegisterCommand('forcerestart', function(source, args)
    if source == 0 or IsPlayerAceAllowed(source, 'admin') then -- Console or admin
        EndQuickGame('Game force restarted by admin')
        friendGame.restartVotes = {}
        
        SetTimeout(2000, function()
            TriggerEvent('cr:startQuickGame', 'classic')
        end)
    end
end, true)

RegisterCommand('clearscores', function(source, args)
    if source == 0 or IsPlayerAceAllowed(source, 'admin') then
        friendGame.scores = {}
        TriggerClientEvent('QBCore:Notify', -1, 'All scores cleared!', 'info')
    end
end, true)

RegisterCommand('quickstart', function(source, args)
    local mode = args[1] or 'classic'
    TriggerEvent('cr:startQuickGame', mode)
end, false)

-- Initialize server
CreateThread(function()
    print("^2[Cops & Robbers]^7 Friend features loaded!")
    print("^3Available commands:^7")
    print("  /quickstart [mode] - Start quick game")
    print("  /forcerestart - Force restart (admin)")
    print("  /clearscores - Clear all scores (admin)")
end)
