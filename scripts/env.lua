_DEBUG = false
_CHEATS = false
_DUMP_ENV = false
_STAGE = {
  settings = 1,
  data = 2,
  migration = 3,
  control = 4,
  init = 5,
  load = 6,
  config_change = 7,
  runtime = 8
}
_LIFECYCLE = _STAGE.control

local Event = require 'utils.event'

--- @class player_settings
--- @field active string 'items'|'stacks'
--- @field items number
--- @field stacks number

--- @class storage table
--- @field pin table<player_index, bool>
--- @field settings table<player_index, player_settings>

Event.on_init(function()
  storage.pin = {}
  storage.settings = {}
end)
