fx_version 'cerulean'
game 'gta5'

author 'TrigX1'
description 'Core Forum'
version '1.0.0'

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- Dependência do MySQL
    'server.lua'
}

files {
    'html/index.html',
    'html/app.js',
    'html/styles.css',
    'html/assets/*.png'
}

dependencies {
    'oxmysql',
    'qb-core' -- Assumindo que você está usando QBCore
}
