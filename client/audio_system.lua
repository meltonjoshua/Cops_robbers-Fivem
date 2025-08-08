-- Audio System for Enhanced Immersion
local audioEnabled = true
local currentAmbientTrack = nil
local radioChannel = nil
local soundVolume = 0.8
local musicVolume = 0.6

-- Audio configuration
local audioConfig = {
    police_radio = {
        sounds = {
            "SCANNER_CHATTER_01", "SCANNER_CHATTER_02", "SCANNER_CHATTER_03",
            "RADIO_STATIC_01", "RADIO_BEEP_01", "RADIO_CONFIRM_01"
        },
        frequency = 15000 -- Every 15 seconds
    },
    sirens = {
        police = "VEHICLES_HORNS_SIREN_1",
        ambulance = "VEHICLES_HORNS_SIREN_2",
        fire = "VEHICLES_HORNS_FIRETRUCK"
    },
    ambient = {
        chase_music = {
            high_intensity = "RADIO_03_HIPHOP_NEW_LOAD_MUSIC_PACKAGE",
            medium_intensity = "RADIO_17_FUNK_LOAD_MUSIC_PACKAGE",
            low_intensity = "RADIO_04_PUNK_LOAD_MUSIC_PACKAGE"
        },
        bank_heist = "RADIO_07_DANCE_02_LOAD_MUSIC_PACKAGE",
        stealth_mode = "RADIO_14_DANCE_02_LOAD_MUSIC_PACKAGE"
    },
    effects = {
        arrest_success = "HUD_CHECKPOINT_PERFECT",
        escape_success = "HUD_MINI_GAME_SOUNDSET",
        bank_alarm = "MP_PROPERTIES_ELEVATOR_DOORS",
        evidence_found = "PICK_UP",
        hack_success = "HACKING_SUCCESS",
        hack_failure = "HACKING_FAILURE",
        level_up = "RACE_PLACED",
        achievement = "MEDAL_BRONZE"
    }
}

-- Current audio state
local audioState = {
    chaseIntensity = 0, -- 0-100
    inStealth = false,
    nearPolice = false,
    inVehicle = false,
    lastRadioChatter = 0,
    currentMusic = nil,
    activeSounds = {}
}

-- Initialize audio system
function InitializeAudioSystem()
    CreateThread(function()
        while true do
            if gameActive then
                UpdateAudioState()
                UpdateAmbientMusic()
                UpdatePoliceRadio()
                UpdateEnvironmentalAudio()
            end
            Wait(1000)
        end
    end)
    
    ShowNotification("🔊 Audio system initialized", "info")
end

-- Update audio state based on gameplay
function UpdateAudioState()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    -- Update vehicle state
    audioState.inVehicle = vehicle ~= 0
    
    -- Calculate chase intensity based on proximity to enemies
    local intensity = 0
    local nearbyEnemies = 0
    
    if playerTeam then
        for _, player in ipairs(GetActivePlayers()) do
            if player ~= PlayerId() then
                local targetPed = GetPlayerPed(player)
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(playerCoords - targetCoords)
                
                if distance <= 100.0 then -- Within 100 meters
                    nearbyEnemies = nearbyEnemies + 1
                    local proximityIntensity = math.max(0, 100 - distance)
                    intensity = math.max(intensity, proximityIntensity)
                end
            end
        end
    end
    
    -- Check if player is being pursued (has wanted level or is in active chase)
    local wantedLevel = GetPlayerWantedLevel(PlayerId())
    if wantedLevel > 0 then
        intensity = math.min(100, intensity + (wantedLevel * 20))
    end
    
    -- Check vehicle speed for chase intensity
    if audioState.inVehicle then
        local speed = GetEntitySpeed(vehicle) * 3.6 -- Convert to km/h
        if speed > 80 then
            intensity = math.min(100, intensity + ((speed - 80) / 2))
        end
    end
    
    audioState.chaseIntensity = intensity
    audioState.nearPolice = nearbyEnemies > 0 and playerTeam == "robber"
    
    -- Stealth detection (player crouched and moving slowly)
    local isMoving = GetEntitySpeed(playerPed) < 2.0
    local isCrouched = IsPedDucking(playerPed)
    audioState.inStealth = isMoving and isCrouched and playerTeam == "robber"
end

-- Update ambient music based on game state
function UpdateAmbientMusic()
    local targetMusic = nil
    
    if audioState.inStealth then
        targetMusic = audioConfig.ambient.stealth_mode
    elseif exports.game_modes and exports.game_modes:GetCurrentGameMode() == "bank_heist" then
        targetMusic = audioConfig.ambient.bank_heist
    elseif audioState.chaseIntensity > 70 then
        targetMusic = audioConfig.ambient.chase_music.high_intensity
    elseif audioState.chaseIntensity > 40 then
        targetMusic = audioConfig.ambient.chase_music.medium_intensity
    elseif audioState.chaseIntensity > 10 then
        targetMusic = audioConfig.ambient.chase_music.low_intensity
    end
    
    -- Change music if needed
    if targetMusic ~= audioState.currentMusic then
        if audioState.currentMusic then
            StopAudioStream()
        end
        
        if targetMusic then
            PlayAudioStream(targetMusic, musicVolume)
            audioState.currentMusic = targetMusic
        else
            audioState.currentMusic = nil
        end
    end
end

-- Update police radio chatter
function UpdatePoliceRadio()
    if playerTeam ~= "cop" then return end
    
    local currentTime = GetGameTimer()
    if currentTime - audioState.lastRadioChatter > audioConfig.police_radio.frequency then
        audioState.lastRadioChatter = currentTime
        
        -- Play random radio chatter
        local sounds = audioConfig.police_radio.sounds
        local randomSound = sounds[math.random(#sounds)]
        
        PlaySoundFromEntity(-1, randomSound, PlayerPedId(), "HUD_FRONTEND_DEFAULT_SOUNDSET", false, 0)
        
        -- Generate contextual radio messages
        GenerateRadioChatter()
    end
end

-- Generate contextual radio chatter
function GenerateRadioChatter()
    local messages = {
        "Dispatch, this is unit " .. PlayerId() .. ", requesting backup",
        "All units, suspect vehicle spotted in the area",
        "Unit " .. PlayerId() .. " in pursuit of suspect",
        "Dispatch, requesting roadblock at intersection",
        "All units, be advised: armed suspects in the area",
        "Unit " .. PlayerId() .. " responding to robbery in progress"
    }
    
    if audioState.chaseIntensity > 50 then
        table.insert(messages, "High-speed pursuit in progress!")
        table.insert(messages, "Requesting helicopter support!")
        table.insert(messages, "Suspect vehicle is evading at high speed!")
    end
    
    local randomMessage = messages[math.random(#messages)]
    TriggerEvent('chat:addMessage', {
        color = {0, 100, 255},
        multiline = true,
        args = {"[POLICE RADIO]", randomMessage}
    })
end

-- Update environmental audio
function UpdateEnvironmentalAudio()
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    -- Play bank alarms if near banks during heist mode
    if exports.game_modes and exports.game_modes:GetCurrentGameMode() == "bank_heist" then
        -- Check proximity to banks (simplified)
        local bankLocations = {
            {x = 147.0, y = -1038.0, z = 29.4},
            {x = 255.0, y = 225.0, z = 101.9},
            {x = -1212.9, y = -336.0, z = 37.8}
        }
        
        for _, bank in ipairs(bankLocations) do
            local distance = #(playerCoords - vector3(bank.x, bank.y, bank.z))
            if distance <= 50.0 then
                PlayAmbientSpeech("GENERIC_CURSE_HIGH", PlayerPedId(), "SPEECH_PARAMS_FORCE_NORMAL", 0)
                break
            end
        end
    end
end

-- Play sound effect
function PlaySoundEffect(effectName, volume)
    if not audioEnabled then return end
    
    local soundData = audioConfig.effects[effectName]
    if soundData then
        local actualVolume = volume or soundVolume
        PlaySoundFrontend(-1, soundData, "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
    end
end

-- Play positional sound
function PlayPositionalSound(effectName, coords, volume, range)
    if not audioEnabled then return end
    
    local soundData = audioConfig.effects[effectName]
    if soundData then
        local actualVolume = volume or soundVolume
        local actualRange = range or 50.0
        
        -- Calculate distance falloff
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distance = #(playerCoords - coords)
        
        if distance <= actualRange then
            local falloff = 1.0 - (distance / actualRange)
            local adjustedVolume = actualVolume * falloff
            
            PlaySoundFromCoord(-1, soundData, coords.x, coords.y, coords.z, "HUD_FRONTEND_DEFAULT_SOUNDSET", false, adjustedVolume, false)
        end
    end
end

-- Vehicle siren system
function ToggleSiren(vehicle, sirenType)
    if not audioEnabled or not vehicle then return end
    
    sirenType = sirenType or "police"
    local sirenSound = audioConfig.sirens[sirenType]
    
    if sirenSound then
        if IsVehicleSirenOn(vehicle) then
            SetVehicleHasMutedSirens(vehicle, true)
        else
            SetVehicleHasMutedSirens(vehicle, false)
            SetVehicleSiren(vehicle, true)
        end
    end
end

-- Audio settings
function SetAudioEnabled(enabled)
    audioEnabled = enabled
    
    if not enabled then
        StopAudioStream()
        audioState.currentMusic = nil
    end
    
    ShowNotification("🔊 Audio " .. (enabled and "enabled" or "disabled"), "info")
end

function SetSoundVolume(volume)
    soundVolume = math.max(0.0, math.min(1.0, volume))
    ShowNotification("🔊 Sound volume: " .. math.floor(soundVolume * 100) .. "%", "info")
end

function SetMusicVolume(volume)
    musicVolume = math.max(0.0, math.min(1.0, volume))
    ShowNotification("🎵 Music volume: " .. math.floor(musicVolume * 100) .. "%", "info")
end

-- Event handlers for game events
RegisterNetEvent('cr:playArrestSound')
AddEventHandler('cr:playArrestSound', function()
    PlaySoundEffect("arrest_success")
end)

RegisterNetEvent('cr:playEscapeSound')
AddEventHandler('cr:playEscapeSound', function()
    PlaySoundEffect("escape_success")
end)

RegisterNetEvent('cr:playBankAlarm')
AddEventHandler('cr:playBankAlarm', function(coords)
    PlayPositionalSound("bank_alarm", coords, 1.0, 100.0)
end)

RegisterNetEvent('cr:playHackSound')
AddEventHandler('cr:playHackSound', function(success)
    PlaySoundEffect(success and "hack_success" or "hack_failure")
end)

RegisterNetEvent('cr:playLevelUpSound')
AddEventHandler('cr:playLevelUpSound', function()
    PlaySoundEffect("level_up")
end)

RegisterNetEvent('cr:playAchievementSound')
AddEventHandler('cr:playAchievementSound', function()
    PlaySoundEffect("achievement")
end)

-- Commands for audio control
RegisterCommand('audio_toggle', function()
    SetAudioEnabled(not audioEnabled)
end, false)

RegisterCommand('sound_volume', function(source, args)
    if args[1] then
        local volume = tonumber(args[1])
        if volume then
            SetSoundVolume(volume / 100.0)
        end
    end
end, false)

RegisterCommand('music_volume', function(source, args)
    if args[1] then
        local volume = tonumber(args[1])
        if volume then
            SetMusicVolume(volume / 100.0)
        end
    end
end, false)

-- Initialize when script loads
CreateThread(function()
    Wait(2000) -- Wait for other systems
    InitializeAudioSystem()
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if audioState.currentMusic then
            StopAudioStream()
        end
    end
end)

-- Export functions
exports('PlaySoundEffect', PlaySoundEffect)
exports('PlayPositionalSound', PlayPositionalSound)
exports('ToggleSiren', ToggleSiren)
exports('SetAudioEnabled', SetAudioEnabled)
exports('SetSoundVolume', SetSoundVolume)
exports('SetMusicVolume', SetMusicVolume)
