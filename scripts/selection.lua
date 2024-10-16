local Event = require 'utils.event'
local SU = require 'scripts.selection_util'

local function is_valid_selection(event)
  if event.item ~= 'logistic_helper_tool' then
    return false
  end
  if not next(event.entities) then
    return false
  end
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return false
  end
  return true
end

local function on_selection(event)
  if not is_valid_selection(event) then
    return
  end
  local player_settings = storage.settings[event.player_index]
  SU.set_info(event.entities, player_settings)
end
Event.add(defines.events.on_player_selected_area, on_selection)
Event.add(defines.events.on_player_alt_selected_area, on_selection)

local function on_deselection(event)
  if not is_valid_selection(event) then
    return
  end
  SU.remove_info(event.entities)
end
Event.add(defines.events.on_player_reverse_selected_area, on_deselection)
Event.add(defines.events.on_player_alt_reverse_selected_area, on_deselection)
