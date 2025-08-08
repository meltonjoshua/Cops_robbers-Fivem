-- Character Selection System
local isInCharacterSelection = false
local selectedCharacter = nil
local selectedTeam = nil
local availableTeams = {}

-- Character selection events
RegisterNetEvent('cr:startCharacterSelection')
AddEventHandler('cr:startCharacterSelection', function(teams)
    availableTeams = teams
    isInCharacterSelection = true
    selectedCharacter = nil
    selectedTeam = nil
    
    -- Show character selection UI
    SendNUIMessage({
        type = "showCharacterSelection",
        characters = Config.CharacterModels,
        availableTeams = availableTeams
    })
    
    SetNuiFocus(true, true)
    ShowNotification(Config.Messages.characterSelectionStarted, "info")
end)

RegisterNetEvent('cr:hideCharacterSelection')
AddEventHandler('cr:hideCharacterSelection', function()
    isInCharacterSelection = false
    SendNUIMessage({
        type = "hideCharacterSelection"
    })
    SetNuiFocus(false, false)
end)

-- NUI Callbacks for character selection
RegisterNUICallback('selectCharacter', function(data, cb)
    selectedCharacter = data.character
    selectedTeam = data.team
    
    -- Preview the character
    if selectedCharacter then
        PreviewCharacter(selectedCharacter.model)
    end
    
    cb('ok')
end)

RegisterNUICallback('confirmSelection', function(data, cb)
    if selectedCharacter and selectedTeam then
        -- Send selection to server
        TriggerServerEvent('cr:characterSelected', {
            character = selectedCharacter,
            teamPreference = selectedTeam
        })
        
        -- Hide selection UI
        TriggerEvent('cr:hideCharacterSelection')
        ShowNotification("Character selected: " .. selectedCharacter.name, "success")
    else
        ShowNotification("Please select both a character and team preference", "error")
    end
    cb('ok')
end)

RegisterNUICallback('closeCharacterSelection', function(data, cb)
    TriggerEvent('cr:hideCharacterSelection')
    cb('ok')
end)

-- Character preview system
local previewPed = nil
local originalPed = nil

function PreviewCharacter(modelHash)
    local playerPed = PlayerPedId()
    
    -- Store original ped if not stored
    if not originalPed then
        originalPed = {
            model = GetEntityModel(playerPed),
            coords = GetEntityCoords(playerPed),
            heading = GetEntityHeading(playerPed)
        }
    end
    
    -- Load the character model
    local model = GetHashKey(modelHash)
    RequestModel(model)
    
    CreateThread(function()
        while not HasModelLoaded(model) do
            Wait(1)
        end
        
        -- Change player model temporarily
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
        
        -- Apply some basic appearance
        local newPed = PlayerPedId()
        SetPedDefaultComponentVariation(newPed)
        SetPedRandomComponentVariation(newPed, false)
    end)
end

function RestoreOriginalCharacter()
    if originalPed then
        local model = originalPed.model
        RequestModel(model)
        
        CreateThread(function()
            while not HasModelLoaded(model) do
                Wait(1)
            end
            
            SetPlayerModel(PlayerId(), model)
            SetEntityCoords(PlayerPedId(), originalPed.coords)
            SetEntityHeading(PlayerPedId(), originalPed.heading)
            SetModelAsNoLongerNeeded(model)
            
            originalPed = nil
        end)
    end
end

-- Apply selected character when team is assigned
RegisterNetEvent('cr:applySelectedCharacter')
AddEventHandler('cr:applySelectedCharacter', function(characterData)
    if characterData and characterData.model then
        local model = GetHashKey(characterData.model)
        RequestModel(model)
        
        CreateThread(function()
            while not HasModelLoaded(model) do
                Wait(1)
            end
            
            SetPlayerModel(PlayerId(), model)
            SetPedDefaultComponentVariation(PlayerPedId())
            SetModelAsNoLongerNeeded(model)
            
            ShowNotification("You are now playing as: " .. characterData.name, "success")
        end)
    end
end)

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isInCharacterSelection then
            SetNuiFocus(false, false)
        end
        if originalPed then
            RestoreOriginalCharacter()
        end
    end
end)
