fx_version 'cerulean'
game 'gta5'

author 'GitHub Copilot'
description 'Cops and Robbers Script with Chase System'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/blips.lua',
    'client/arrest.lua',
    'client/character_selection.lua',
    'client/keybinds.lua'
}

server_scripts {
    'server/main.lua',
    'server/game.lua',
    'server/version.lua'
}

files {
    'html/ui.html',
    'html/style.css',
    'html/script.js',
    'html/character_selection.html',
    'html/character_selection.css',
    'html/character_selection.js'
}

ui_page 'html/ui.html'
