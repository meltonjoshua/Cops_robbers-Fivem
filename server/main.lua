local gameActive = false
local gamePlayers = {}
local cops = {}
local robbers = {}
local arrestedRobbers = {}
local gameEndTime = 0
local playersInSelection = {}
local playerCharacterData = {}

-- Initialize player data
function InitializePlayer(source)
    gamePlayers[source] = {
        team = nil,
        arrested = false,
        position = nil,
        character = nil
    }
end

-- Start a new game
function StartGame()
    if gameActive then
        return false, Config.Messages.alreadyInGame
    end
    
    local playerCount = GetNumPlayerIndices()
    if playerCount < Config.MinPlayers then
        return false, Config.Messages.notEnoughPlayers
    end
    
    -- Start character selection phase
    StartCharacterSelection()
    
    return true, "Character selection started. Players can now choose their characters and teams."
end

-- Start character selection phase
function StartCharacterSelection()
    playersInSelection = {}
    playerCharacterData = {}
    
    local players = GetPlayers()
    local availableTeams = {"cop", "robber"} -- Both teams available during selection
    
    for i = 1, #players do
        local playerId = tonumber(players[i])
        if playerId then
            playersInSelection[playerId] = true
            TriggerClientEvent('cr:startCharacterSelection', playerId, availableTeams)
        end
    end
    
    -- Set timeout for character selection (30 seconds)
    CreateThread(function()
        Wait(30000) -- 30 seconds
        
        -- Auto-assign any players who didn't select
        for playerId, _ in pairs(playersInSelection) do
            if not playerCharacterData[playerId] then
                -- Auto-assign random character and team
                playerCharacterData[playerId] = {
                    character = {model = "mp_m_freemode_01", name = "Default Character"},
                    teamPreference = "random"
                }
            end
        end
        
        -- Start actual game
        StartActualGame()
    end)
end

-- Handle character selection from client
function HandleCharacterSelection(source, data)
    if not playersInSelection[source] then
        return
    end
    
    playerCharacterData[source] = data
    playersInSelection[source] = nil -- Mark as completed
    
    TriggerClientEvent('cr:hideCharacterSelection', source)
    TriggerClientEvent('cr:notify', source, "Character selection confirmed. Waiting for other players...")
    
    -- Check if all players have selected
    local allSelected = true
    for playerId, _ in pairs(playersInSelection) do
        allSelected = false
        break
    end
    
    if allSelected then
        -- All players selected, start game immediately
        StartActualGame()
    end
end

-- Start the actual game after character selection
function StartActualGame()
    gameActive = true
    gamePlayers = {}
    cops = {}
    robbers = {}
    arrestedRobbers = {}
    gameEndTime = GetGameTimer() + (Config.GameDuration * 1000)
    
    local players = GetPlayers()
    local robberCount = math.min(math.floor(#players / 2), Config.MaxRobbers)
    local copCount = #players - robberCount
    
    -- Separate players by team preference
    local copPreferences = {}
    local robberPreferences = {}
    local randomPreferences = {}
    
    for i = 1, #players do
        local playerId = tonumber(players[i])
        if playerId and playerCharacterData[playerId] then
            local preference = playerCharacterData[playerId].teamPreference
            if preference == "cop" then
                table.insert(copPreferences, playerId)
            elseif preference == "robber" then
                table.insert(robberPreferences, playerId)
            else
                table.insert(randomPreferences, playerId)
            end
        else
            table.insert(randomPreferences, playerId) -- Default to random
        end
    end
    
    -- Assign teams based on preferences and balance
    local assignedCops = {}
    local assignedRobbers = {}
    
    -- First, assign preferred cops (up to the limit)
    for i = 1, math.min(#copPreferences, copCount) do
        assignedCops[copPreferences[i]] = true
    end
    
    -- Then assign preferred robbers (up to the limit)
    local remainingRobberSlots = robberCount
    for i = 1, math.min(#robberPreferences, remainingRobberSlots) do
        assignedRobbers[robberPreferences[i]] = true
        remainingRobberSlots = remainingRobberSlots - 1
    end
    
    -- Fill remaining slots with random and overflow preferences
    local unassigned = {}
    
    -- Add overflow cop preferences to unassigned
    for i = copCount + 1, #copPreferences do
        table.insert(unassigned, copPreferences[i])
    end
    
    -- Add overflow robber preferences to unassigned
    for i = robberCount - remainingRobberSlots + 1, #robberPreferences do
        table.insert(unassigned, robberPreferences[i])
    end
    
    -- Add random preferences to unassigned
    for i = 1, #randomPreferences do
        table.insert(unassigned, randomPreferences[i])
    end
    
    -- Shuffle unassigned players
    for i = #unassigned, 2, -1 do
        local j = math.random(i)
        unassigned[i], unassigned[j] = unassigned[j], unassigned[i]
    end
    
    -- Fill remaining cop slots
    local remainingCopSlots = copCount - #assignedCops
    for i = 1, math.min(remainingCopSlots, #unassigned) do
        assignedCops[unassigned[i]] = true
    end
    
    -- Fill remaining robber slots
    for i = remainingCopSlots + 1, #unassigned do
        if remainingRobberSlots > 0 then
            assignedRobbers[unassigned[i]] = true
            remainingRobberSlots = remainingRobberSlots - 1
        end
    end
    
    -- Apply team assignments and characters
    for playerId, _ in pairs(assignedCops) do
        cops[playerId] = true
        gamePlayers[playerId] = {
            team = "cop",
            arrested = false,
            character = playerCharacterData[playerId] and playerCharacterData[playerId].character
        }
        TriggerClientEvent('cr:assignTeam', playerId, 'cop')
        if gamePlayers[playerId].character then
            TriggerClientEvent('cr:applySelectedCharacter', playerId, gamePlayers[playerId].character)
        end
    end
    
    for playerId, _ in pairs(assignedRobbers) do
        robbers[playerId] = true
        gamePlayers[playerId] = {
            team = "robber",
            arrested = false,
            character = playerCharacterData[playerId] and playerCharacterData[playerId].character
        }
        TriggerClientEvent('cr:assignTeam', playerId, 'robber')
        if gamePlayers[playerId].character then
            TriggerClientEvent('cr:applySelectedCharacter', playerId, gamePlayers[playerId].character)
        end
    end
    
    -- Notify all players
    TriggerClientEvent('cr:gameStarted', -1)
    TriggerClientEvent('cr:updateGameTimer', -1, Config.GameDuration)
    
    -- Start game timer
    CreateThread(function()
        while gameActive and GetGameTimer() < gameEndTime do
            Wait(1000)
            local timeLeft = math.max(0, math.floor((gameEndTime - GetGameTimer()) / 1000))
            TriggerClientEvent('cr:updateGameTimer', -1, timeLeft)
        end
        
        if gameActive then
            EndGame('robbers')
        end
    end)
    
    -- Clear selection data
    playersInSelection = {}
    playerCharacterData = {}
end

-- End the game
function EndGame(winner)
    if not gameActive then return end
    
    gameActive = false
    
    local message = winner == 'cops' and Config.Messages.copsWin or Config.Messages.robbersWin
    
    TriggerClientEvent('cr:gameEnded', -1, winner, message)
    TriggerClientEvent('cr:cleanup', -1)
    
    -- Reset all data
    gamePlayers = {}
    cops = {}
    robbers = {}
    arrestedRobbers = {}
end

-- Arrest a robber
function ArrestRobber(copId, robberId)
    if not gameActive then return false end
    if not cops[copId] or not robbers[robberId] then return false end
    if arrestedRobbers[robberId] then return false end
    
    arrestedRobbers[robberId] = true
    gamePlayers[robberId].arrested = true
    
    TriggerClientEvent('cr:arrested', robberId)
    TriggerClientEvent('cr:arrestedSomeone', copId, GetPlayerName(robberId))
    TriggerClientEvent('cr:removeBlip', -1, robberId)
    
    -- Check if all robbers are arrested
    local allArrested = true
    for robber, _ in pairs(robbers) do
        if not arrestedRobbers[robber] then
            allArrested = false
            break
        end
    end
    
    if allArrested then
        EndGame('cops')
    end
    
    return true
end

-- Player disconnection handling
AddEventHandler('playerDropped', function()
    local source = source
    if gamePlayers[source] then
        if cops[source] then
            cops[source] = nil
        elseif robbers[source] then
            robbers[source] = nil
            arrestedRobbers[source] = nil
        end
        gamePlayers[source] = nil
        
        TriggerClientEvent('cr:removeBlip', -1, source)
    end
end)

-- Export functions for other scripts
exports('StartGame', StartGame)
exports('EndGame', EndGame)
exports('IsGameActive', function() return gameActive end)
exports('GetGamePlayers', function() return gamePlayers end)
