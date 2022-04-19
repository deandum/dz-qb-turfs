fx_version 'cerulean'
game 'gta5'

description 'dz-qb-turfs'
author 'Dean Zaral <https://github.com/deandum>'
repository 'https://github.com/deandum/dq-qb-turfs'
version '1.0.0'

shared_scripts {
  'shared/*.lua',
  'config.lua'
}

client_scripts {
  '@PolyZone/client.lua',
  '@PolyZone/CircleZone.lua',
  'client/*.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/*.lua'
}

lua54 'yes'
