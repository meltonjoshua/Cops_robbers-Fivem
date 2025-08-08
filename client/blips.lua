local blips = {}
local blipsEnabled = false

-- Create blip for player
local function CreatePlayerBlip(playerId, team)
    local player = GetPlayerFromServerId(playerId)
    if player == -1 then return end
    
    local ped = GetPlayerPed(player)
    if ped == 0 then return end
    
    -- Remove existing blip
    if blips[playerId] then
        RemoveBlip(blips[playerId])
    end
    
    -- Don't create blip for self
    if player == PlayerId() then return end
    
    -- Create new blip
    local blip = AddBlipForEntity(ped)
    local config = Config.BlipSettings[team]
    
    if config then
        SetBlipSprite(blip, config.sprite)
        SetBlipColour(blip, config.color)
        SetBlipScale(blip, config.scale)
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(config.name .. " - " .. GetPlayerName(player))
        EndTextCommandSetBlipName(blip)
        
        blips[playerId] = blip
    end
end

-- Update player position and blip
RegisterNetEvent('cr:updatePlayerPosition')
AddEventHandler('cr:updatePlayerPosition', function(playerId, coords, team)
    if not blipsEnabled then return end
    
    -- Update or create blip
    if team and team ~= playerTeam then -- Only show enemy team blips
        CreatePlayerBlip(playerId, team)
    end
end)

-- Remove specific blip
RegisterNetEvent('cr:removeBlip')
AddEventHandler('cr:removeBlip', function(playerId)
    if blips[playerId] then
        RemoveBlip(blips[playerId])
        blips[playerId] = nil
    end
end)

-- Enable blips system
RegisterNetEvent('cr:enableBlips')
AddEventHandler('cr:enableBlips', function()
    blipsEnabled = true
end)

-- Disable blips system
RegisterNetEvent('cr:disableBlips')
AddEventHandler('cr:disableBlips', function()
    blipsEnabled = false
    
    -- Remove all blips
    for playerId, blip in pairs(blips) do
        RemoveBlip(blip)
    end
    blips = {}
end)

-- Update blips periodically
CreateThread(function()
    while true do
        if blipsEnabled and gameActive then
            -- Clean up invalid blips
            for playerId, blip in pairs(blips) do
                if not DoesBlipExist(blip) then
                    blips[playerId] = nil
                end
            end
        end
        Wait(5000) -- Check every 5 seconds
    end
end)

-- Handle player disconnections
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Clean up all blips
        for playerId, blip in pairs(blips) do
            RemoveBlip(blip)
        end
        blips = {}
    end
end)
