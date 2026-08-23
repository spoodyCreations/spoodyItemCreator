fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Spoody'
description 'Item Creator'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

server_scripts {
    'server/version.lua',
    'server/main.lua',
}
client_script 'client/main.lua'

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*.js',
    'web/dist/assets/*.css',
}

dependency 'ox_inventory'
