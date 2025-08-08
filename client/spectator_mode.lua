-- Spectator Mode for Eliminated Players
local spectatorMode = {
    isSpectating = false,
    targetPlayer = nil,
    spectatorType = "free", -- "free", "player", "fixed"
    fixedCameras = {},
    currentCamera = 1,
    spectatorUI = nil
}

-- Spectator configuration
local spectatorConfig = {
    freeCamera = {
        speed = 1.0,
        fastSpeed = 3.0,
        maxHeight = 500.0,
        minHeight = 10.0
    },
    playerCamera = {
        distance = 5.0,
        height = 2.0,
        switchCooldown = 2000 -- 2 seconds
    },
    fixedCameras = {
        {coords = {x = 425.0, y = -978.0, z = 50.0}, rotation = {x = -30.0, y = 0.0, z = 0.0}, name = "Police Station"},
        {coords = {x = 240.0, y = -862.0, z = 80.0}, rotation = {x = -45.0, y = 0.0, z = 180.0}, name = "Downtown"},
        {coords = {x = -1037.0, y = -2738.0, z = 60.0}, rotation = {x = -20.0, y = 0.0, z = 270.0}, name = "Airport"},
        {coords = {x = 1729.0, y = 3307.0, z = 70.0}, rotation = {x = -35.0, y = 0.0, z = 45.0}, name = "Sandy Shores"},
        {coords = {x = -241.0, y = 6179.0, z = 50.0}, rotation = {x = -25.0, y = 0.0, z = 315.0}, name = "Paleto Bay"}
    },
    ui = {
        position = {x = 0.02, y = 0.85},
        width = 0.25,
        height = 0.12
    }
}

-- Current spectator state
local spectatorState = {
    camera = nil,
    lastSwitchTime = 0,
    freeCamPosition = nil,
    freeCamRotation = nil,
    previousPosition = nil,
    playersToSpectate = {},
    currentPlayerIndex = 1
}

-- Initialize spectator mode
function InitializeSpectatorMode()
    CreateSpectatorUI()
    
    -- Register keybinds for spectator mode
    RegisterKeyMapping('spectator_switch_type', 'Switch Spectator Mode', 'keyboard', 'TAB')
    RegisterKeyMapping('spectator_next_player', 'Next Player', 'keyboard', 'RIGHT')
    RegisterKeyMapping('spectator_prev_player', 'Previous Player', 'keyboard', 'LEFT')
    RegisterKeyMapping('spectator_next_camera', 'Next Fixed Camera', 'keyboard', 'UP')
    RegisterKeyMapping('spectator_prev_camera', 'Previous Fixed Camera', 'keyboard', 'DOWN')
    RegisterKeyMapping('spectator_toggle_ui', 'Toggle Spectator UI', 'keyboard', 'H')
    
    ShowNotification("👁️ Spectator mode initialized", "info")
end

-- Enter spectator mode
function EnterSpectatorMode(reason)
    if spectatorMode.isSpectating then return end
    
    spectatorMode.isSpectating = true
    spectatorState.previousPosition = GetEntityCoords(PlayerPedId())
    
    -- Make player invisible and disable controls
    local playerPed = PlayerPedId()
    SetEntityVisible(playerPed, false, false)
    SetEntityCollision(playerPed, false, false)
    FreezeEntityPosition(playerPed, true)
    SetEntityInvincible(playerPed, true)
    
    -- Disable player input
    SetPlayerControl(PlayerId(), false, 0)
    
    -- Get list of active players to spectate
    UpdateSpectatorPlayerList()
    
    -- Start with player spectator mode
    SetSpectatorMode("player")
    
    -- Show spectator UI
    ShowSpectatorUI(true)
    
    -- Notify
    local reasonText = reason or "eliminated"
    ShowNotification("👁️ Entering spectator mode (" .. reasonText .. ")", "info")
    
    -- Start spectator loop
    CreateSpectatorThread()
end

-- Exit spectator mode
function ExitSpectatorMode()
    if not spectatorMode.isSpectating then return end
    
    spectatorMode.isSpectating = false
    
    -- Destroy spectator camera
    if spectatorState.camera then
        RenderScriptCams(false, true, 1000, true, false)
        DestroyCam(spectatorState.camera, false)
        spectatorState.camera = nil
    end
    
    -- Restore player
    local playerPed = PlayerPedId()
    SetEntityVisible(playerPed, true, false)
    SetEntityCollision(playerPed, true, true)
    FreezeEntityPosition(playerPed, false)
    SetEntityInvincible(playerPed, false)
    SetPlayerControl(PlayerId(), true, 0)
    
    -- Hide spectator UI
    ShowSpectatorUI(false)
    
    -- Teleport player to safe location if needed
    if spectatorState.previousPosition then
        SetEntityCoords(playerPed, spectatorState.previousPosition.x, spectatorState.previousPosition.y, spectatorState.previousPosition.z)
    end
    
    ShowNotification("✅ Exited spectator mode", "success")
end

-- Set spectator mode type
function SetSpectatorMode(mode)
    spectatorMode.spectatorType = mode
    
    -- Destroy existing camera
    if spectatorState.camera then
        RenderScriptCams(false, true, 500, true, false)
        DestroyCam(spectatorState.camera, false)
        spectatorState.camera = nil
    end
    
    if mode == "free" then
        SetupFreeCamera()
    elseif mode == "player" then
        SetupPlayerCamera()
    elseif mode == "fixed" then
        SetupFixedCamera()
    end
    
    UpdateSpectatorUI()
end

-- Setup free camera
function SetupFreeCamera()
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    spectatorState.camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    
    -- Position camera above current location
    if not spectatorState.freeCamPosition then
        spectatorState.freeCamPosition = {
            x = playerCoords.x,
            y = playerCoords.y,
            z = playerCoords.z + 50.0
        }
    end
    
    if not spectatorState.freeCamRotation then
        spectatorState.freeCamRotation = {x = -30.0, y = 0.0, z = 0.0}
    end
    
    SetCamCoord(spectatorState.camera, 
        spectatorState.freeCamPosition.x, 
        spectatorState.freeCamPosition.y, 
        spectatorState.freeCamPosition.z)
    SetCamRot(spectatorState.camera, 
        spectatorState.freeCamRotation.x, 
        spectatorState.freeCamRotation.y, 
        spectatorState.freeCamRotation.z, 2)
    
    SetCamActive(spectatorState.camera, true)
    RenderScriptCams(true, true, 1000, true, false)
end

-- Setup player following camera
function SetupPlayerCamera()
    if #spectatorState.playersToSpectate == 0 then
        ShowNotification("❌ No players available to spectate", "error")
        SetSpectatorMode("free")
        return
    end
    
    spectatorMode.targetPlayer = spectatorState.playersToSpectate[spectatorState.currentPlayerIndex]
    
    if not spectatorMode.targetPlayer or not NetworkIsPlayerActive(spectatorMode.targetPlayer) then
        SwitchToNextPlayer()
        return
    end
    
    spectatorState.camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    UpdatePlayerCamera()
    
    SetCamActive(spectatorState.camera, true)
    RenderScriptCams(true, true, 1000, true, false)
end

-- Setup fixed camera
function SetupFixedCamera()
    if #spectatorConfig.fixedCameras == 0 then
        SetSpectatorMode("free")
        return
    end
    
    spectatorMode.currentCamera = math.max(1, math.min(spectatorMode.currentCamera, #spectatorConfig.fixedCameras))
    local camera = spectatorConfig.fixedCameras[spectatorMode.currentCamera]
    
    spectatorState.camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    
    SetCamCoord(spectatorState.camera, camera.coords.x, camera.coords.y, camera.coords.z)
    SetCamRot(spectatorState.camera, camera.rotation.x, camera.rotation.y, camera.rotation.z, 2)
    
    SetCamActive(spectatorState.camera, true)
    RenderScriptCams(true, true, 1000, true, false)
end

-- Update player camera position
function UpdatePlayerCamera()
    if not spectatorMode.targetPlayer or not spectatorState.camera then return end
    
    local targetPed = GetPlayerPed(spectatorMode.targetPlayer)
    if not DoesEntityExist(targetPed) then
        SwitchToNextPlayer()
        return
    end
    
    local targetCoords = GetEntityCoords(targetPed)
    local targetHeading = GetEntityHeading(targetPed)
    
    -- Calculate camera position behind and above target
    local distance = spectatorConfig.playerCamera.distance
    local height = spectatorConfig.playerCamera.height
    
    local behindX = targetCoords.x - (math.sin(math.rad(targetHeading)) * distance)
    local behindY = targetCoords.y + (math.cos(math.rad(targetHeading)) * distance)
    local behindZ = targetCoords.z + height
    
    SetCamCoord(spectatorState.camera, behindX, behindY, behindZ)
    PointCamAtEntity(spectatorState.camera, targetPed, 0.0, 0.0, 0.0, true)
end

-- Update list of players to spectate
function UpdateSpectatorPlayerList()
    spectatorState.playersToSpectate = {}
    
    for playerId = 0, 255 do
        if NetworkIsPlayerActive(playerId) and playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            if DoesEntityExist(targetPed) and not IsEntityDead(targetPed) then
                table.insert(spectatorState.playersToSpectate, playerId)
            end
        end
    end
    
    if spectatorState.currentPlayerIndex > #spectatorState.playersToSpectate then
        spectatorState.currentPlayerIndex = 1
    end
end

-- Switch to next player
function SwitchToNextPlayer()
    local currentTime = GetGameTimer()
    if currentTime - spectatorState.lastSwitchTime < spectatorConfig.playerCamera.switchCooldown then
        return
    end
    
    spectatorState.lastSwitchTime = currentTime
    UpdateSpectatorPlayerList()
    
    if #spectatorState.playersToSpectate == 0 then
        ShowNotification("❌ No players available to spectate", "error")
        return
    end
    
    spectatorState.currentPlayerIndex = spectatorState.currentPlayerIndex + 1
    if spectatorState.currentPlayerIndex > #spectatorState.playersToSpectate then
        spectatorState.currentPlayerIndex = 1
    end
    
    spectatorMode.targetPlayer = spectatorState.playersToSpectate[spectatorState.currentPlayerIndex]
    
    if spectatorMode.spectatorType == "player" then
        UpdatePlayerCamera()
    end
    
    local playerName = GetPlayerName(spectatorMode.targetPlayer)
    ShowNotification("👁️ Now spectating: " .. playerName, "info")
    UpdateSpectatorUI()
end

-- Switch to previous player
function SwitchToPreviousPlayer()
    local currentTime = GetGameTimer()
    if currentTime - spectatorState.lastSwitchTime < spectatorConfig.playerCamera.switchCooldown then
        return
    end
    
    spectatorState.lastSwitchTime = currentTime
    UpdateSpectatorPlayerList()
    
    if #spectatorState.playersToSpectate == 0 then
        return
    end
    
    spectatorState.currentPlayerIndex = spectatorState.currentPlayerIndex - 1
    if spectatorState.currentPlayerIndex < 1 then
        spectatorState.currentPlayerIndex = #spectatorState.playersToSpectate
    end
    
    spectatorMode.targetPlayer = spectatorState.playersToSpectate[spectatorState.currentPlayerIndex]
    
    if spectatorMode.spectatorType == "player" then
        UpdatePlayerCamera()
    end
    
    local playerName = GetPlayerName(spectatorMode.targetPlayer)
    ShowNotification("👁️ Now spectating: " .. playerName, "info")
    UpdateSpectatorUI()
end

-- Free camera movement
function UpdateFreeCamera()
    if spectatorMode.spectatorType ~= "free" or not spectatorState.camera then return end
    
    local speed = spectatorConfig.freeCamera.speed
    if IsControlPressed(0, 21) then -- Left Shift for fast movement
        speed = spectatorConfig.freeCamera.fastSpeed
    end
    
    local camCoords = GetCamCoord(spectatorState.camera)
    local camRot = GetCamRot(spectatorState.camera, 2)
    
    -- Movement controls
    local forward = IsControlPressed(0, 32) -- W
    local backward = IsControlPressed(0, 33) -- S
    local left = IsControlPressed(0, 34) -- A
    local right = IsControlPressed(0, 35) -- D
    local up = IsControlPressed(0, 44) -- Q
    local down = IsControlPressed(0, 46) -- E
    
    -- Mouse look
    local mouseX = GetControlNormal(0, 1) * 5.0
    local mouseY = GetControlNormal(0, 2) * 5.0
    
    -- Update rotation
    spectatorState.freeCamRotation.z = spectatorState.freeCamRotation.z - mouseX
    spectatorState.freeCamRotation.x = math.max(-90.0, math.min(90.0, spectatorState.freeCamRotation.x - mouseY))
    
    -- Calculate movement vectors
    local radZ = math.rad(spectatorState.freeCamRotation.z)
    local radX = math.rad(spectatorState.freeCamRotation.x)
    
    local forwardX = math.sin(radZ) * math.cos(radX)
    local forwardY = math.cos(radZ) * math.cos(radX)
    local forwardZ = math.sin(radX)
    
    local rightX = math.cos(radZ)
    local rightY = -math.sin(radZ)
    
    -- Apply movement
    local moveX = 0.0
    local moveY = 0.0
    local moveZ = 0.0
    
    if forward then
        moveX = moveX + forwardX * speed
        moveY = moveY + forwardY * speed
        moveZ = moveZ + forwardZ * speed
    end
    if backward then
        moveX = moveX - forwardX * speed
        moveY = moveY - forwardY * speed
        moveZ = moveZ - forwardZ * speed
    end
    if left then
        moveX = moveX - rightX * speed
        moveY = moveY - rightY * speed
    end
    if right then
        moveX = moveX + rightX * speed
        moveY = moveY + rightY * speed
    end
    if up then
        moveZ = moveZ + speed
    end
    if down then
        moveZ = moveZ - speed
    end
    
    -- Update position
    spectatorState.freeCamPosition.x = spectatorState.freeCamPosition.x + moveX
    spectatorState.freeCamPosition.y = spectatorState.freeCamPosition.y + moveY
    spectatorState.freeCamPosition.z = math.max(
        spectatorConfig.freeCamera.minHeight,
        math.min(spectatorConfig.freeCamera.maxHeight, spectatorState.freeCamPosition.z + moveZ)
    )
    
    -- Apply to camera
    SetCamCoord(spectatorState.camera, 
        spectatorState.freeCamPosition.x, 
        spectatorState.freeCamPosition.y, 
        spectatorState.freeCamPosition.z)
    SetCamRot(spectatorState.camera, 
        spectatorState.freeCamRotation.x, 
        spectatorState.freeCamRotation.y, 
        spectatorState.freeCamRotation.z, 2)
end

-- Main spectator thread
function CreateSpectatorThread()
    CreateThread(function()
        while spectatorMode.isSpectating do
            -- Update based on spectator type
            if spectatorMode.spectatorType == "free" then
                UpdateFreeCamera()
            elseif spectatorMode.spectatorType == "player" then
                UpdatePlayerCamera()
            end
            
            -- Disable all player controls
            DisableAllControlActions(0)
            
            -- Enable only spectator controls
            EnableControlAction(0, 1, true) -- Mouse look
            EnableControlAction(0, 2, true) -- Mouse look
            EnableControlAction(0, 245, true) -- Chat
            
            Wait(0)
        end
    end)
end

-- Create spectator UI
function CreateSpectatorUI()
    spectatorMode.spectatorUI = true -- Placeholder for UI creation
end

-- Show/hide spectator UI
function ShowSpectatorUI(show)
    -- Send to NUI
    SendNUIMessage({
        type = "showSpectatorUI",
        show = show,
        data = GetSpectatorUIData()
    })
end

-- Update spectator UI
function UpdateSpectatorUI()
    if not spectatorMode.isSpectating then return end
    
    SendNUIMessage({
        type = "updateSpectatorUI",
        data = GetSpectatorUIData()
    })
end

-- Get spectator UI data
function GetSpectatorUIData()
    local data = {
        mode = spectatorMode.spectatorType,
        playerCount = #spectatorState.playersToSpectate,
        currentPlayer = spectatorState.currentPlayerIndex,
        targetPlayerName = "",
        cameraName = "",
        controls = {
            ["TAB"] = "Switch Mode",
            ["LEFT/RIGHT"] = "Switch Player",
            ["UP/DOWN"] = "Fixed Camera",
            ["WASD"] = "Free Camera",
            ["Q/E"] = "Up/Down",
            ["SHIFT"] = "Fast Mode",
            ["H"] = "Toggle UI"
        }
    }
    
    if spectatorMode.targetPlayer then
        data.targetPlayerName = GetPlayerName(spectatorMode.targetPlayer)
    end
    
    if spectatorMode.spectatorType == "fixed" then
        local camera = spectatorConfig.fixedCameras[spectatorMode.currentCamera]
        if camera then
            data.cameraName = camera.name
        end
    end
    
    return data
end

-- Command handlers
RegisterCommand('spectator_switch_type', function()
    if not spectatorMode.isSpectating then return end
    
    local modes = {"free", "player", "fixed"}
    local currentIndex = 1
    
    for i, mode in ipairs(modes) do
        if mode == spectatorMode.spectatorType then
            currentIndex = i
            break
        end
    end
    
    currentIndex = currentIndex + 1
    if currentIndex > #modes then
        currentIndex = 1
    end
    
    SetSpectatorMode(modes[currentIndex])
    ShowNotification("👁️ Spectator mode: " .. modes[currentIndex], "info")
end, false)

RegisterCommand('spectator_next_player', function()
    if spectatorMode.isSpectating then
        SwitchToNextPlayer()
    end
end, false)

RegisterCommand('spectator_prev_player', function()
    if spectatorMode.isSpectating then
        SwitchToPreviousPlayer()
    end
end, false)

RegisterCommand('spectator_next_camera', function()
    if spectatorMode.isSpectating and spectatorMode.spectatorType == "fixed" then
        spectatorMode.currentCamera = spectatorMode.currentCamera + 1
        if spectatorMode.currentCamera > #spectatorConfig.fixedCameras then
            spectatorMode.currentCamera = 1
        end
        SetupFixedCamera()
        UpdateSpectatorUI()
    end
end, false)

RegisterCommand('spectator_prev_camera', function()
    if spectatorMode.isSpectating and spectatorMode.spectatorType == "fixed" then
        spectatorMode.currentCamera = spectatorMode.currentCamera - 1
        if spectatorMode.currentCamera < 1 then
            spectatorMode.currentCamera = #spectatorConfig.fixedCameras
        end
        SetupFixedCamera()
        UpdateSpectatorUI()
    end
end, false)

RegisterCommand('spectator_toggle_ui', function()
    if spectatorMode.isSpectating then
        -- Toggle UI visibility
        SendNUIMessage({
            type = "toggleSpectatorUI"
        })
    end
end, false)

-- Event handlers
RegisterNetEvent('cr:enterSpectatorMode')
AddEventHandler('cr:enterSpectatorMode', function(reason)
    EnterSpectatorMode(reason)
end)

RegisterNetEvent('cr:exitSpectatorMode')
AddEventHandler('cr:exitSpectatorMode', function()
    ExitSpectatorMode()
end)

-- Auto-enter spectator mode when eliminated
RegisterNetEvent('cr:playerEliminated')
AddEventHandler('cr:playerEliminated', function()
    if gameActive and playerStats.health <= 0 then
        CreateThread(function()
            Wait(3000) -- Wait 3 seconds before entering spectator mode
            EnterSpectatorMode("eliminated")
        end)
    end
end)

-- Initialize when script starts
CreateThread(function()
    Wait(2000)
    InitializeSpectatorMode()
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if spectatorMode.isSpectating then
            ExitSpectatorMode()
        end
    end
end)

-- Export functions
exports('EnterSpectatorMode', EnterSpectatorMode)
exports('ExitSpectatorMode', ExitSpectatorMode)
exports('IsSpectating', function() return spectatorMode.isSpectating end)
exports('GetSpectatorMode', function() return spectatorMode.spectatorType end)
