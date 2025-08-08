-- Statistics and Progression System
local playerStats = {
    totalGames = 0,
    gamesWon = 0,
    gamesLost = 0,
    arrestsMade = 0,
    timesArrested = 0,
    moneyStolen = 0,
    timesSurvived = 0,
    killCount = 0,
    deathCount = 0,
    bestSurvivalTime = 0,
    bankRobberies = 0,
    territoriesCaptured = 0,
    vipEscorts = 0,
    level = 1,
    experience = 0,
    totalPlayTime = 0,
    lastGameTime = 0,
    achievements = {},
    preferences = {
        favoriteTeam = "none",
        favoriteGameMode = "classic",
        preferredCharacter = 1
    }
}

local currentSessionStats = {
    gameStartTime = 0,
    sessionArrests = 0,
    sessionMoney = 0,
    sessionSurvivalTime = 0,
    sessionKills = 0,
    sessionDeaths = 0
}

local achievements = {
    {id = "first_game", name = "First Timer", description = "Play your first game", unlocked = false, xp = 100},
    {id = "first_win", name = "Victory!", description = "Win your first game", unlocked = false, xp = 200},
    {id = "arrest_master", name = "Arrest Master", description = "Make 50 arrests", unlocked = false, xp = 500, requirement = 50},
    {id = "escape_artist", name = "Escape Artist", description = "Escape arrest 25 times", unlocked = false, xp = 300, requirement = 25},
    {id = "money_bags", name = "Money Bags", description = "Steal $1,000,000", unlocked = false, xp = 1000, requirement = 1000000},
    {id = "survivor", name = "Survivor", description = "Survive for 30 minutes total", unlocked = false, xp = 400, requirement = 1800000}, -- 30 minutes in ms
    {id = "sharpshooter", name = "Sharpshooter", description = "Get 100 kills", unlocked = false, xp = 600, requirement = 100},
    {id = "bank_buster", name = "Bank Buster", description = "Rob 20 banks", unlocked = false, xp = 750, requirement = 20},
    {id = "territory_king", name = "Territory King", description = "Capture 50 territories", unlocked = false, xp = 800, requirement = 50},
    {id = "vip_guardian", name = "VIP Guardian", description = "Successfully escort 10 VIPs", unlocked = false, xp = 650, requirement = 10},
    {id = "wave_warrior", name = "Wave Warrior", description = "Survive to wave 10 in survival mode", unlocked = false, xp = 900, requirement = 10},
    {id = "perfectionist", name = "Perfectionist", description = "Win 10 games in a row", unlocked = false, xp = 1500, requirement = 10},
    {id = "veteran", name = "Veteran", description = "Play for 10 hours total", unlocked = false, xp = 2000, requirement = 36000000}, -- 10 hours in ms
    {id = "legendary", name = "Legendary", description = "Reach level 25", unlocked = false, xp = 5000, requirement = 25}
}

local levelRequirements = {}
local maxLevel = 50

-- Initialize level requirements (exponential growth)
function InitializeLevelSystem()
    levelRequirements[1] = 0
    for i = 2, maxLevel do
        levelRequirements[i] = math.floor(100 * (i - 1) * (1.5 ^ (i - 1)))
    end
end

-- Load player statistics
function LoadPlayerStats()
    local data = GetResourceKvpString("cr_player_stats")
    if data then
        local decoded = json.decode(data)
        if decoded then
            for k, v in pairs(decoded) do
                if playerStats[k] ~= nil then
                    playerStats[k] = v
                end
            end
        end
    end
    
    -- Load achievements
    local achievementData = GetResourceKvpString("cr_achievements")
    if achievementData then
        local decoded = json.decode(achievementData)
        if decoded then
            for _, achievement in ipairs(achievements) do
                if decoded[achievement.id] then
                    achievement.unlocked = true
                end
            end
        end
    end
    
    CalculateLevel()
    CheckAchievements()
end

-- Save player statistics
function SavePlayerStats()
    SetResourceKvp("cr_player_stats", json.encode(playerStats))
    
    -- Save achievements
    local unlockedAchievements = {}
    for _, achievement in ipairs(achievements) do
        if achievement.unlocked then
            unlockedAchievements[achievement.id] = true
        end
    end
    SetResourceKvp("cr_achievements", json.encode(unlockedAchievements))
end

-- Calculate player level based on experience
function CalculateLevel()
    local newLevel = 1
    for level = 2, maxLevel do
        if playerStats.experience >= levelRequirements[level] then
            newLevel = level
        else
            break
        end
    end
    
    if newLevel > playerStats.level then
        local oldLevel = playerStats.level
        playerStats.level = newLevel
        ShowNotification("🎉 Level Up! You are now level " .. newLevel, "success")
        
        -- Level up rewards
        local bonusXP = newLevel * 10
        AddExperience(bonusXP, "Level up bonus!")
        
        TriggerServerEvent('cr:levelUp', oldLevel, newLevel)
    end
end

-- Add experience points
function AddExperience(amount, reason)
    playerStats.experience = playerStats.experience + amount
    
    ShowNotification("+" .. amount .. " XP" .. (reason and (" - " .. reason) or ""), "info")
    
    CalculateLevel()
    SavePlayerStats()
    
    -- Update UI
    SendNUIMessage({
        type = "updateStats",
        stats = GetDisplayStats()
    })
end

-- Start game session tracking
function StartGameSession()
    currentSessionStats.gameStartTime = GetGameTimer()
    currentSessionStats.sessionArrests = 0
    currentSessionStats.sessionMoney = 0
    currentSessionStats.sessionSurvivalTime = 0
    currentSessionStats.sessionKills = 0
    currentSessionStats.sessionDeaths = 0
    
    playerStats.totalGames = playerStats.totalGames + 1
    
    CheckAchievements()
    SavePlayerStats()
end

-- End game session tracking
function EndGameSession(won, team)
    local sessionTime = GetGameTimer() - currentSessionStats.gameStartTime
    
    playerStats.totalPlayTime = playerStats.totalPlayTime + sessionTime
    playerStats.lastGameTime = sessionTime
    
    if won then
        playerStats.gamesWon = playerStats.gamesWon + 1
        AddExperience(100, "Game victory!")
    else
        playerStats.gamesLost = playerStats.gamesLost + 1
        AddExperience(25, "Participation")
    end
    
    -- Survival time bonus
    local survivalMinutes = math.floor(sessionTime / 60000)
    if survivalMinutes > 0 then
        AddExperience(survivalMinutes * 5, "Survival time bonus")
        currentSessionStats.sessionSurvivalTime = sessionTime
        
        if sessionTime > playerStats.bestSurvivalTime then
            playerStats.bestSurvivalTime = sessionTime
        end
    end
    
    -- Update preferences
    if playerStats.preferences.favoriteTeam == "none" or math.random() > 0.7 then
        playerStats.preferences.favoriteTeam = team
    end
    
    CheckAchievements()
    SavePlayerStats()
    
    -- Show session summary
    ShowSessionSummary()
end

-- Record various game events
function RecordArrest(arrested)
    if arrested then
        playerStats.timesArrested = playerStats.timesArrested + 1
        currentSessionStats.sessionDeaths = currentSessionStats.sessionDeaths + 1
        AddExperience(5, "Learning experience")
    else
        playerStats.arrestsMade = playerStats.arrestsMade + 1
        currentSessionStats.sessionArrests = currentSessionStats.sessionArrests + 1
        AddExperience(25, "Arrest made!")
    end
    
    CheckAchievements()
    SavePlayerStats()
end

function RecordMoneyStolen(amount)
    playerStats.moneyStolen = playerStats.moneyStolen + amount
    currentSessionStats.sessionMoney = currentSessionStats.sessionMoney + amount
    
    local xpGain = math.floor(amount / 1000) -- 1 XP per $1000
    AddExperience(xpGain, "Money stolen!")
    
    CheckAchievements()
    SavePlayerStats()
end

function RecordBankRobbery()
    playerStats.bankRobberies = playerStats.bankRobberies + 1
    AddExperience(50, "Bank robbery!")
    
    CheckAchievements()
    SavePlayerStats()
end

function RecordTerritoryCapture()
    playerStats.territoriesCaptured = playerStats.territoriesCaptured + 1
    AddExperience(30, "Territory captured!")
    
    CheckAchievements()
    SavePlayerStats()
end

function RecordVipEscort()
    playerStats.vipEscorts = playerStats.vipEscorts + 1
    AddExperience(75, "VIP escort!")
    
    CheckAchievements()
    SavePlayerStats()
end

function RecordKill()
    playerStats.killCount = playerStats.killCount + 1
    currentSessionStats.sessionKills = currentSessionStats.sessionKills + 1
    AddExperience(15, "Elimination!")
    
    CheckAchievements()
    SavePlayerStats()
end

function RecordDeath()
    playerStats.deathCount = playerStats.deathCount + 1
    currentSessionStats.sessionDeaths = currentSessionStats.sessionDeaths + 1
    
    CheckAchievements()
    SavePlayerStats()
end

-- Check and unlock achievements
function CheckAchievements()
    for _, achievement in ipairs(achievements) do
        if not achievement.unlocked then
            local shouldUnlock = false
            
            if achievement.id == "first_game" and playerStats.totalGames >= 1 then
                shouldUnlock = true
            elseif achievement.id == "first_win" and playerStats.gamesWon >= 1 then
                shouldUnlock = true
            elseif achievement.id == "arrest_master" and playerStats.arrestsMade >= achievement.requirement then
                shouldUnlock = true
            elseif achievement.id == "escape_artist" and playerStats.timesArrested >= achievement.requirement then
                shouldUnlock = true
            elseif achievement.id == "money_bags" and playerStats.moneyStolen >= achievement.requirement then
                shouldUnlock = true
            elseif achievement.id == "survivor" and playerStats.totalPlayTime >= achievement.requirement then
                shouldUnlock = true
            elseif achievement.id == "sharpshooter" and playerStats.killCount >= achievement.requirement then
                shouldUnlock = true
            elseif achievement.id == "bank_buster" and playerStats.bankRobberies >= achievement.requirement then
                shouldUnlock = true
            elseif achievement.id == "territory_king" and playerStats.territoriesCaptured >= achievement.requirement then
                shouldUnlock = true
            elseif achievement.id == "vip_guardian" and playerStats.vipEscorts >= achievement.requirement then
                shouldUnlock = true
            elseif achievement.id == "legendary" and playerStats.level >= achievement.requirement then
                shouldUnlock = true
            end
            
            if shouldUnlock then
                UnlockAchievement(achievement)
            end
        end
    end
end

-- Unlock achievement
function UnlockAchievement(achievement)
    achievement.unlocked = true
    playerStats.achievements[achievement.id] = true
    
    ShowNotification("🏆 Achievement Unlocked: " .. achievement.name, "success")
    ShowNotification(achievement.description, "info")
    
    AddExperience(achievement.xp, "Achievement: " .. achievement.name)
    SavePlayerStats()
    
    -- Special achievement effects
    CreateThread(function()
        PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)
        Wait(2000)
    end)
end

-- Get stats for display
function GetDisplayStats()
    local winRate = playerStats.totalGames > 0 and math.floor((playerStats.gamesWon / playerStats.totalGames) * 100) or 0
    local kdr = playerStats.deathCount > 0 and math.floor((playerStats.killCount / playerStats.deathCount) * 100) / 100 or playerStats.killCount
    local nextLevelXP = playerStats.level < maxLevel and levelRequirements[playerStats.level + 1] or 0
    local xpProgress = nextLevelXP > 0 and math.floor((playerStats.experience / nextLevelXP) * 100) or 100
    
    return {
        level = playerStats.level,
        experience = playerStats.experience,
        nextLevelXP = nextLevelXP,
        xpProgress = xpProgress,
        totalGames = playerStats.totalGames,
        gamesWon = playerStats.gamesWon,
        gamesLost = playerStats.gamesLost,
        winRate = winRate,
        arrestsMade = playerStats.arrestsMade,
        timesArrested = playerStats.timesArrested,
        moneyStolen = playerStats.moneyStolen,
        killCount = playerStats.killCount,
        deathCount = playerStats.deathCount,
        kdr = kdr,
        bestSurvivalTime = math.floor(playerStats.bestSurvivalTime / 60000),
        bankRobberies = playerStats.bankRobberies,
        territoriesCaptured = playerStats.territoriesCaptured,
        vipEscorts = playerStats.vipEscorts,
        totalPlayTime = math.floor(playerStats.totalPlayTime / 3600000), -- Hours
        achievements = achievements,
        sessionStats = currentSessionStats
    }
end

-- Show session summary
function ShowSessionSummary()
    local sessionTime = math.floor((GetGameTimer() - currentSessionStats.gameStartTime) / 60000)
    
    SendNUIMessage({
        type = "showSessionSummary",
        data = {
            sessionTime = sessionTime,
            arrests = currentSessionStats.sessionArrests,
            money = currentSessionStats.sessionMoney,
            kills = currentSessionStats.sessionKills,
            deaths = currentSessionStats.sessionDeaths,
            level = playerStats.level,
            experience = playerStats.experience
        }
    })
end

-- Reset statistics (admin command)
function ResetStats()
    playerStats = {
        totalGames = 0,
        gamesWon = 0,
        gamesLost = 0,
        arrestsMade = 0,
        timesArrested = 0,
        moneyStolen = 0,
        timesSurvived = 0,
        killCount = 0,
        deathCount = 0,
        bestSurvivalTime = 0,
        bankRobberies = 0,
        territoriesCaptured = 0,
        vipEscorts = 0,
        level = 1,
        experience = 0,
        totalPlayTime = 0,
        lastGameTime = 0,
        achievements = {},
        preferences = {
            favoriteTeam = "none",
            favoriteGameMode = "classic",
            preferredCharacter = 1
        }
    }
    
    for _, achievement in ipairs(achievements) do
        achievement.unlocked = false
    end
    
    SavePlayerStats()
    ShowNotification("Statistics reset successfully!", "info")
end

-- Initialize on resource start
CreateThread(function()
    InitializeLevelSystem()
    LoadPlayerStats()
    
    -- Update UI with stats
    SendNUIMessage({
        type = "updateStats",
        stats = GetDisplayStats()
    })
end)

-- Export functions
exports('StartGameSession', StartGameSession)
exports('EndGameSession', EndGameSession)
exports('RecordArrest', RecordArrest)
exports('RecordMoneyStolen', RecordMoneyStolen)
exports('RecordBankRobbery', RecordBankRobbery)
exports('RecordTerritoryCapture', RecordTerritoryCapture)
exports('RecordVipEscort', RecordVipEscort)
exports('RecordKill', RecordKill)
exports('RecordDeath', RecordDeath)
exports('GetDisplayStats', GetDisplayStats)
exports('AddExperience', AddExperience)
exports('ResetStats', ResetStats)
