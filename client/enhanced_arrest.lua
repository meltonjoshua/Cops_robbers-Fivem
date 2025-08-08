-- Enhanced Arrest System with Handcuffs and Resistance
local arrestAnimDict = "mp_arresting"
local handcuffDict = "mp_arrest_paired"
local resistanceEnabled = true
local arrestRequiresEvidence = false

-- Enhanced arrest states
local arrestStates = {
    NONE = 0,
    INITIATING = 1,
    IN_PROGRESS = 2,
    HANDCUFFING = 3,
    RESISTING = 4,
    COMPLETED = 5
}

local currentArrestState = arrestStates.NONE
local arrestData = {
    targetId = nil,
    startTime = 0,
    resistanceTime = 0,
    evidence = 0,
    resistanceStrength = 0
}

-- Load animations
CreateThread(function()
    local anims = {arrestAnimDict, handcuffDict, "random@mugging3"}
    for _, dict in ipairs(anims) do
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(1)
        end
    end
end)

-- Enhanced arrest mechanics
local function StartEnhancedArrest(targetId)
    if currentArrestState ~= arrestStates.NONE then return false end
    
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    if not targetPed or targetPed == 0 then return false end
    
    -- Check if evidence is required
    if arrestRequiresEvidence and arrestData.evidence < Config.RequiredEvidence then
        ShowNotification("Insufficient evidence to arrest! Collect more evidence first.", "error")
        return false
    end
    
    currentArrestState = arrestStates.INITIATING
    arrestData.targetId = targetId
    arrestData.startTime = GetGameTimer()
    arrestData.resistanceStrength = math.random(1, 5) -- Random resistance level
    
    -- Start arrest animation
    local playerPed = PlayerPedId()
    TaskPlayAnim(playerPed, arrestAnimDict, "arrest_cop", 8.0, -8, -1, 1, 0, 0, 0, 0)
    
    ShowNotification("Starting arrest procedure...", "info")
    TriggerServerEvent('cr:startArrest', targetId)
    
    return true
end

-- Resistance system for robbers
local function HandleResistance()
    if currentArrestState ~= arrestStates.IN_PROGRESS then return end
    
    local resistanceChance = math.random(1, 100)
    local breakFreeChance = 20 + (arrestData.resistanceStrength * 5) -- Higher resistance = better chance
    
    if resistanceChance <= breakFreeChance then
        currentArrestState = arrestStates.RESISTING
        ShowNotification("The suspect is resisting arrest!", "warning")
        
        -- Enable resistance minigame
        StartResistanceMinigame()
    else
        -- Continue with arrest
        currentArrestState = arrestStates.HANDCUFFING
        ShowHandcuffingSequence()
    end
end

-- Resistance minigame for robbers
function StartResistanceMinigame()
    local resistanceTime = GetGameTimer() + 3000 -- 3 seconds to resist
    local successfulResistance = false
    
    CreateThread(function()
        while GetGameTimer() < resistanceTime and currentArrestState == arrestStates.RESISTING do
            -- Show resistance prompt
            DisplayHelpText("~r~RESISTING ARREST!~w~ Rapidly press ~INPUT_FRONTEND_ACCEPT~ to break free!")
            
            if IsControlJustPressed(0, 201) then -- Enter key for resistance
                arrestData.resistanceTime = arrestData.resistanceTime + 100
                
                -- Check if resistance was successful
                if arrestData.resistanceTime >= 2000 then -- Need 2 seconds of resistance
                    successfulResistance = true
                    break
                end
            end
            
            Wait(0)
        end
        
        if successfulResistance then
            -- Robber broke free
            currentArrestState = arrestStates.NONE
            arrestData = {targetId = nil, startTime = 0, resistanceTime = 0, evidence = 0, resistanceStrength = 0}
            
            ShowNotification("You broke free from the arrest!", "success")
            TriggerServerEvent('cr:resistedArrest', arrestData.targetId)
            
            -- Give robber temporary speed boost
            local playerPed = PlayerPedId()
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.5)
            SetTimeout(5000, function()
                SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
            end)
        else
            -- Failed to resist, complete arrest
            currentArrestState = arrestStates.HANDCUFFING
            ShowHandcuffingSequence()
        end
    end)
end

-- Handcuffing sequence
function ShowHandcuffingSequence()
    local playerPed = PlayerPedId()
    local targetPed = GetPlayerPed(GetPlayerFromServerId(arrestData.targetId))
    
    if not targetPed or targetPed == 0 then
        currentArrestState = arrestStates.NONE
        return
    end
    
    -- Play handcuffing animation
    TaskPlayAnim(playerPed, handcuffDict, "cop_p2_back_right", 8.0, -8, 3000, 1, 0, 0, 0, 0)
    
    ShowNotification("Applying handcuffs...", "info")
    
    SetTimeout(3000, function()
        currentArrestState = arrestStates.COMPLETED
        CompleteArrest()
    end)
end

-- Complete the arrest
function CompleteArrest()
    if arrestData.targetId then
        TriggerServerEvent('cr:requestArrest', arrestData.targetId)
        ShowNotification("Arrest completed successfully!", "success")
        
        -- Reset arrest data
        currentArrestState = arrestStates.NONE
        arrestData = {targetId = nil, startTime = 0, resistanceTime = 0, evidence = 0, resistanceStrength = 0}
        
        -- Clear animations
        ClearPedTasks(PlayerPedId())
    end
end

-- Evidence collection system
local function CollectEvidence(evidenceType)
    arrestData.evidence = arrestData.evidence + 1
    ShowNotification("Evidence collected (" .. arrestData.evidence .. "/" .. Config.RequiredEvidence .. ")", "info")
    
    -- Update UI with evidence count
    SendNUIMessage({
        type = "updateEvidence",
        count = arrestData.evidence,
        required = Config.RequiredEvidence
    })
end

-- Enhanced arrest prompts with evidence system
CreateThread(function()
    while true do
        if gameActive and playerTeam == "cop" and not isArrested then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            for _, player in ipairs(GetActivePlayers()) do
                if player ~= PlayerId() then
                    local targetPed = GetPlayerPed(player)
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(playerCoords - targetCoords)
                    
                    if distance <= Config.ArrestDistance then
                        local targetId = GetPlayerServerId(player)
                        
                        if currentArrestState == arrestStates.NONE then
                            -- Show arrest prompt with evidence requirement
                            local promptText = "~g~[E]~w~ Arrest Robber"
                            if arrestRequiresEvidence then
                                if arrestData.evidence >= Config.RequiredEvidence then
                                    promptText = promptText .. " ~g~(Evidence: " .. arrestData.evidence .. "/" .. Config.RequiredEvidence .. ")"
                                else
                                    promptText = "~r~[E]~w~ Need Evidence (" .. arrestData.evidence .. "/" .. Config.RequiredEvidence .. ")"
                                end
                            end
                            
                            DrawText3D(targetCoords.x, targetCoords.y, targetCoords.z + 1.2, promptText)
                            
                            if IsControlJustPressed(0, 38) then -- E key
                                StartEnhancedArrest(targetId)
                            end
                        elseif currentArrestState == arrestStates.IN_PROGRESS and arrestData.targetId == targetId then
                            -- Show arrest progress
                            local progress = (GetGameTimer() - arrestData.startTime) / Config.ArrestTime
                            DrawText3D(targetCoords.x, targetCoords.y, targetCoords.z + 1.2, 
                                "~y~Arresting... " .. math.floor(progress * 100) .. "%")
                            
                            if progress >= 1.0 then
                                HandleResistance()
                            end
                        end
                        break
                    end
                end
            end
        end
        Wait(0)
    end
end)

-- Team arrest system - multiple cops can arrest faster
local teamArrestData = {}

function StartTeamArrest(targetId)
    if not teamArrestData[targetId] then
        teamArrestData[targetId] = {
            cops = {},
            startTime = GetGameTimer()
        }
    end
    
    teamArrestData[targetId].cops[PlayerId()] = true
    
    -- Calculate team arrest bonus
    local copCount = 0
    for _ in pairs(teamArrestData[targetId].cops) do
        copCount = copCount + 1
    end
    
    -- Faster arrest with more cops
    local arrestSpeedMultiplier = 1 + (copCount - 1) * 0.3 -- 30% faster per additional cop
    return arrestSpeedMultiplier
end

-- Export functions for other scripts
exports('StartEnhancedArrest', StartEnhancedArrest)
exports('CollectEvidence', CollectEvidence)
exports('GetArrestState', function() return currentArrestState end)

-- Events for server communication
RegisterNetEvent('cr:arrestResisted')
AddEventHandler('cr:arrestResisted', function(copId)
    ShowNotification("Arrest was resisted! The suspect broke free.", "warning")
end)

RegisterNetEvent('cr:evidenceFound')
AddEventHandler('cr:evidenceFound', function(evidenceType)
    CollectEvidence(evidenceType)
end)
