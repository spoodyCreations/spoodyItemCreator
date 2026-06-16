fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Spoody & Eugene'
description 'Item Creator — Admin UI for registering custom items into ox_inventory'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

server_script 'server/main.lua'
client_script 'client/main.lua'

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*.js',
    'web/dist/assets/*.css',
}

dependency 'ox_inventory'
