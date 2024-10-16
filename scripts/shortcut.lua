local Event = require 'utils.event'
local Settings = require 'scripts.settings_gui'

local function on_lua_shortcut(event)
  local name = event.input_name or event.prototype_name
  if name ~= 'get_logistic_helper_tool' then
    return
  end
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end
  local cursor_stack = player.cursor_stack
  if cursor_stack and cursor_stack.valid_for_read and cursor_stack_name == 'get_logistic_helper_tool' then
    Settings.toggle_main_frame(player)
    return
  end
  if not cursor_stack or not player.clear_cursor() then
    return
  end
  cursor_stack.set_stack({ name = 'logistic_helper_tool', count = 1 })
  Settings.toggle_main_frame(player)
end
Event.add(defines.events.on_lua_shortcut, on_lua_shortcut)
Event.add('get_logistic_helper_tool', on_lua_shortcut)
