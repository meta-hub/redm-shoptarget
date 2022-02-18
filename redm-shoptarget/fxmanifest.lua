fx_version 'adamant'
games { 'rdr3', 'gta5' }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'
use_fxv2_oal 'yes'

client_scripts {
  '@redm-events/dataview.lua',
  '@redm-events/events.lua',
  's2w.lua',
  'client.lua'
}

dependencies {
  'redm-events'
}