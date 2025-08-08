fx_version 'cerulean'
game 'gta5'

author 'GitHub Copilot'
description 'Cops and Robbers Script with Chase System'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'config.lua',
    'config/friend_config.lua',
    'client/main.lua',
    'client/blips.lua',
    'client/arrest.lua',
    'client/character_selection.lua',
    'client/keybinds.lua',
    'client/enhanced_arrest.lua',
    'client/game_modes.lua',
    'client/statistics.lua',
    'client/environment.lua',
    'client/audio_system.lua',
    'client/vehicle_system.lua',
    'client/dynamic_map.lua',
    'client/spectator_mode.lua',
    'client/friend_features.lua'
}

server_scripts {
    'server/main.lua',
    'server/game.lua',
    'server/version.lua',
    'server/friend_features.lua',
    'server/test_2players.lua'
}

files {
    'html/ui.html',
    'html/style.css',
    'html/script.js',
    'html/character_selection.html',
    'html/character_selection.css',
    'html/character_selection.js',
    'html/enhanced_ui.html',
    'html/enhanced_styles.css',
    'html/enhanced_script.js',
    'html/spectator_ui.html',
    'html/friend_hud.html'
}

ui_page 'html/ui.html'
