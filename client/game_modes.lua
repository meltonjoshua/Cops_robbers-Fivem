-- Game Modes System
local gameModes = {
    CLASSIC = "classic",
    BANK_HEIST = "bank_heist",
    VIP_ESCORT = "vip_escort",
    TERRITORY_CONTROL = "territory_control",
    SURVIVAL = "survival"
}

local currentGameMode = gameModes.CLASSIC
local modeData = {}

-- Bank Heist Mode
local bankHeistData = {
    banks = {
        {name = "Fleeca Bank", coords = {x = 147.0, y = -1038.0, z = 29.4}, robbed = false, money = 50000},
        {name = "Pacific Standard", coords = {x = 255.0, y = 225.0, z = 101.9}, robbed = false, money = 100000},
        {name = "Maze Bank", coords = {x = -1212.9, y = -336.0, z = 37.8}, robbed = false, money = 75000}
    },
    totalMoney = 0,
    requiredMoney = 200000,
    robbedBanks = 0
}

-- VIP Escort Mode
local vipEscortData = {
    vipPlayer = nil,
    escortZones = {
        {name = "Airport", coords = {x = -1037.6, y = -2737.6, z = 20.2}},
        {name = "Police Station", coords = {x = 425.1, y = -979.5, z = 30.7}},
        {name = "Hospital", coords = {x = 295.8, y = -1446.9, z = 29.9}}
    },
    currentZone = 1,
    vipHealth = 100
}

-- Territory Control Mode
local territoryData = {
    zones = {
        {name = "Downtown", coords = {x = 0.0, y = 0.0, z = 30.0}, radius = 100.0, controlledBy = nil, progress = 0},
        {name = "Sandy Shores", coords = {x = 1729.2, y = 3307.5, z = 41.2}, radius = 150.0, controlledBy = nil, progress = 0},
        {name = "Paleto Bay", coords = {x = -241.4, y = 6178.9, z = 31.2}, radius = 120.0, controlledBy = nil, progress = 0}
    },
    captureTime = 30000, -- 30 seconds to capture
    copZones = 0,
    robberZones = 0
}

-- Survival Mode
local survivalData = {
    wave = 1,
    copReinforcements = 0,
    nextWaveTime = 0,
    difficultyMultiplier = 1.0
}

-- Initialize game mode
function InitializeGameMode(mode)
    currentGameMode = mode
    
    if mode == gameModes.BANK_HEIST then
        InitializeBankHeist()
    elseif mode == gameModes.VIP_ESCORT then
        InitializeVipEscort()
    elseif mode == gameModes.TERRITORY_CONTROL then
        InitializeTerritoryControl()
    elseif mode == gameModes.SURVIVAL then
        InitializeSurvival()
    else
        InitializeClassicMode()
    end
    
    -- Update UI with game mode
    SendNUIMessage({
        type = "setGameMode",
        mode = mode,
        data = modeData
    })
end

-- Bank Heist Mode Implementation
function InitializeBankHeist()
    modeData = bankHeistData
    
    -- Create bank blips for robbers
    if playerTeam == "robber" then
        for i, bank in ipairs(bankHeistData.banks) do
            local blip = AddBlipForCoord(bank.coords.x, bank.coords.y, bank.coords.z)
            SetBlipSprite(blip, 108) -- Bank icon
            SetBlipColour(blip, 2) -- Green
            SetBlipScale(blip, 0.8)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(bank.name .. " ($" .. bank.money .. ")")
            EndTextCommandSetBlipName(blip)
            
            bank.blip = blip
        end
        
        ShowNotification("Rob banks to collect $" .. bankHeistData.requiredMoney .. " and escape!", "info")
    else
        ShowNotification("Prevent the robbers from stealing money from the banks!", "info")
    end
    
    -- Start bank heist monitoring
    CreateThread(function()
        while gameActive and currentGameMode == gameModes.BANK_HEIST do
            if playerTeam == "robber" then
                CheckBankRobbery()
            end
            Wait(1000)
        end
    end)
end

function CheckBankRobbery()
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    for i, bank in ipairs(bankHeistData.banks) do
        if not bank.robbed then
            local distance = #(playerCoords - vector3(bank.coords.x, bank.coords.y, bank.coords.z))
            
            if distance <= 5.0 then
                DrawText3D(bank.coords.x, bank.coords.y, bank.coords.z + 1.0, 
                    "~g~[E]~w~ Rob " .. bank.name .. " ($" .. bank.money .. ")")
                
                if IsControlJustPressed(0, 38) then -- E key
                    StartBankRobbery(i)
                end
            end
        end
    end
end

function StartBankRobbery(bankIndex)
    local bank = bankHeistData.banks[bankIndex]
    if bank.robbed then return end
    
    ShowNotification("Robbing " .. bank.name .. "... Stay close!", "warning")
    
    -- Start robbery timer
    local robberyTime = 10000 -- 10 seconds
    local startTime = GetGameTimer()
    
    CreateThread(function()
        while GetGameTimer() - startTime < robberyTime do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - vector3(bank.coords.x, bank.coords.y, bank.coords.z))
            
            if distance > 10.0 then
                ShowNotification("Robbery failed! You moved too far away.", "error")
                return
            end
            
            local progress = (GetGameTimer() - startTime) / robberyTime
            DrawText3D(bank.coords.x, bank.coords.y, bank.coords.z + 1.0, 
                "~y~Robbing... " .. math.floor(progress * 100) .. "%")
            
            Wait(0)
        end
        
        -- Robbery successful
        bank.robbed = true
        bankHeistData.totalMoney = bankHeistData.totalMoney + bank.money
        bankHeistData.robbedBanks = bankHeistData.robbedBanks + 1
        
        RemoveBlip(bank.blip)
        ShowNotification("Successfully robbed " .. bank.name .. "! Total: $" .. bankHeistData.totalMoney, "success")
        
        TriggerServerEvent('cr:bankRobbed', bankIndex, bank.money)
        
        -- Check win condition
        if bankHeistData.totalMoney >= bankHeistData.requiredMoney then
            TriggerServerEvent('cr:gameWon', 'robbers', 'Bank heist completed!')
        end
    end)
end

-- VIP Escort Mode Implementation
function InitializeVipEscort()
    modeData = vipEscortData
    
    if playerTeam == "cop" then
        ShowNotification("Protect the VIP and escort them to safety!", "info")
    else
        ShowNotification("Eliminate the VIP before they reach safety!", "error")
    end
    
    -- VIP escort monitoring
    CreateThread(function()
        while gameActive and currentGameMode == gameModes.VIP_ESCORT do
            if vipEscortData.vipPlayer then
                CheckVipStatus()
                CheckEscortZones()
            end
            Wait(1000)
        end
    end)
end

function CheckVipStatus()
    local vipPed = GetPlayerPed(GetPlayerFromServerId(vipEscortData.vipPlayer))
    if vipPed and vipPed ~= 0 then
        local health = GetEntityHealth(vipPed)
        if health <= 0 then
            TriggerServerEvent('cr:gameWon', 'robbers', 'VIP eliminated!')
        end
    end
end

function CheckEscortZones()
    if vipEscortData.vipPlayer == PlayerId() then
        local playerCoords = GetEntityCoords(PlayerPedId())
        local zone = vipEscortData.escortZones[vipEscortData.currentZone]
        
        if zone then
            local distance = #(playerCoords - vector3(zone.coords.x, zone.coords.y, zone.coords.z))
            
            if distance <= 10.0 then
                vipEscortData.currentZone = vipEscortData.currentZone + 1
                
                if vipEscortData.currentZone > #vipEscortData.escortZones then
                    TriggerServerEvent('cr:gameWon', 'cops', 'VIP successfully escorted!')
                else
                    ShowNotification("Checkpoint reached! Head to the next location.", "success")
                end
            end
        end
    end
end

-- Territory Control Mode Implementation
function InitializeTerritoryControl()
    modeData = territoryData
    
    -- Create territory blips
    for i, zone in ipairs(territoryData.zones) do
        local blip = AddBlipForRadius(zone.coords.x, zone.coords.y, zone.coords.z, zone.radius)
        SetBlipColour(blip, 0) -- White (neutral)
        SetBlipAlpha(blip, 128)
        zone.blip = blip
        
        local markerBlip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
        SetBlipSprite(markerBlip, 84) -- Territory icon
        SetBlipColour(markerBlip, 0)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(zone.name)
        EndTextCommandSetBlipName(markerBlip)
        zone.markerBlip = markerBlip
    end
    
    ShowNotification("Capture and hold territories to win!", "info")
    
    -- Territory control monitoring
    CreateThread(function()
        while gameActive and currentGameMode == gameModes.TERRITORY_CONTROL do
            CheckTerritoryControl()
            Wait(1000)
        end
    end)
end

function CheckTerritoryControl()
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    for i, zone in ipairs(territoryData.zones) do
        local distance = #(playerCoords - vector3(zone.coords.x, zone.coords.y, zone.coords.z))
        
        if distance <= zone.radius then
            -- Player is in territory
            if zone.controlledBy ~= playerTeam then
                zone.progress = zone.progress + 1000 -- 1 second of progress
                
                if zone.progress >= territoryData.captureTime then
                    CaptureTerritory(i)
                end
                
                -- Show capture progress
                local progressPercent = math.floor((zone.progress / territoryData.captureTime) * 100)
                DrawText3D(zone.coords.x, zone.coords.y, zone.coords.z + 10.0, 
                    "~y~Capturing " .. zone.name .. "... " .. progressPercent .. "%")
            end
            break
        end
    end
end

function CaptureTerritory(zoneIndex)
    local zone = territoryData.zones[zoneIndex]
    
    -- Update previous team count
    if zone.controlledBy == "cop" then
        territoryData.copZones = territoryData.copZones - 1
    elseif zone.controlledBy == "robber" then
        territoryData.robberZones = territoryData.robberZones - 1
    end
    
    -- Update new team count
    zone.controlledBy = playerTeam
    zone.progress = 0
    
    if playerTeam == "cop" then
        territoryData.copZones = territoryData.copZones + 1
        SetBlipColour(zone.blip, 3) -- Blue
        SetBlipColour(zone.markerBlip, 3)
    else
        territoryData.robberZones = territoryData.robberZones + 1
        SetBlipColour(zone.blip, 1) -- Red
        SetBlipColour(zone.markerBlip, 1)
    end
    
    ShowNotification("Captured " .. zone.name .. "!", "success")
    TriggerServerEvent('cr:territoryCaptured', zoneIndex, playerTeam)
    
    -- Check win condition (control majority)
    local totalZones = #territoryData.zones
    local majorityNeeded = math.ceil(totalZones / 2)
    
    if territoryData.copZones >= majorityNeeded then
        TriggerServerEvent('cr:gameWon', 'cops', 'Cops control the majority of territories!')
    elseif territoryData.robberZones >= majorityNeeded then
        TriggerServerEvent('cr:gameWon', 'robbers', 'Robbers control the majority of territories!')
    end
end

-- Survival Mode Implementation
function InitializeSurvival()
    modeData = survivalData
    survivalData.nextWaveTime = GetGameTimer() + 60000 -- First wave in 1 minute
    
    ShowNotification("Survival Mode: Waves of reinforcements incoming!", "warning")
    
    CreateThread(function()
        while gameActive and currentGameMode == gameModes.SURVIVAL do
            CheckSurvivalWave()
            Wait(1000)
        end
    end)
end

function CheckSurvivalWave()
    if GetGameTimer() >= survivalData.nextWaveTime then
        survivalData.wave = survivalData.wave + 1
        survivalData.difficultyMultiplier = 1.0 + (survivalData.wave * 0.2)
        survivalData.nextWaveTime = GetGameTimer() + (90000 / survivalData.difficultyMultiplier) -- Shorter intervals
        
        ShowNotification("Wave " .. survivalData.wave .. " incoming! Difficulty increased!", "warning")
        TriggerServerEvent('cr:spawnWave', survivalData.wave)
    end
end

-- Classic Mode (original)
function InitializeClassicMode()
    modeData = {}
    ShowNotification("Classic Cops vs Robbers - Survive for 10 minutes!", "info")
end

-- Export functions
exports('InitializeGameMode', InitializeGameMode)
exports('GetCurrentGameMode', function() return currentGameMode end)
exports('GetModeData', function() return modeData end)
