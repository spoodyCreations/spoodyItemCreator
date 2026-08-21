fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Eugene' -- posted by spoody
description 'Item Creator — DISCONTINUED, moved to https://github.com/Binary-Development/bd_oxeditor'
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
