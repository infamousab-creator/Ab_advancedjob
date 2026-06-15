fx_version 'cerulean'
game 'gta5'

author 'AB'
description 'Advanced Job System - ESX & QBCore Compatible'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua', -- optional, remove if not using ox_lib
    'shared/config.lua',
    'shared/framework.lua',
}

client_scripts {
    'client/main.lua',
    'client/ui.lua',
    'client/blips.lua',
    'client/ped.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- optional, remove if not using oxmysql
    'server/main.lua',
    'server/framework.lua',
    'server/database.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
}

lua54 'yes'
