fx_version 'cerulean'
game 'gta5'

description 'Bees Script'
version '1.5.0'
author 'RijayJH'

lua54 'yes'

shared_scripts { 
	'config.lua',
    '@ox_lib/init.lua'
}

client_scripts{
    'client.lua',
} 

server_scripts{
    'server.lua',
} 