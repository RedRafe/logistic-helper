local Event = require 'utils.event'
local Gui = require 'utils.gui'

local main_frame_name = Gui.uid_name()
local pin_button_name = Gui.uid_name()
local close_button_name = Gui.uid_name()
local radio_button_name = Gui.uid_name()
local text_tag_name = Gui.uid_name()
local slider_tag_name = Gui.uid_name()
local trash_not_requested_name = Gui.uid_name()
local request_from_buffers_name = Gui.uid_name()

local Public = {}

local function get_player_settings(player_index)
  local p_settings = storage.settings[player_index]
  if not p_settings then
    p_settings = {
      active = 'items',
      items = 200,
      stacks = 4,
      trash_not_requested = false,
      request_from_buffers = true,
    }
    storage.settings[player_index] = p_settings
  end
  return p_settings
end

local function make_setting(parent, params)
  local flow = parent.add { type = 'flow', direction = 'horizontal' }
  Gui.set_style(flow, { vertical_align = 'center' })

  local radio = flow.add { type = 'radiobutton', name = radio_button_name, state = params.state }
  table.insert(params.radio_buttons, radio)
  Gui.set_data(radio, { list = params.radio_buttons, key = params.key })

  local right = flow.add { type = 'flow', direction = 'vertical' }
  
  local row_1 = right.add { type = 'flow', style = 'player_input_horizontal_flow' }
  local label = row_1.add { type = 'label', caption = params.caption, style = 'semibold_label' }
  local info = row_1.add { type = 'label', caption = '[img=info]', tooltip = params.tooltip }
  Gui.add_pusher(row_1)
  local text = row_1.add { type = 'textfield', style = 'slider_value_textfield', tags = { name = text_tag_name }, text = tostring(params.value) }
  text.numeric = true

  local row_2 = right.add { type = 'flow', style = 'player_input_horizontal_flow' }
  local slider = row_2.add {
    type = 'slider',
    style = 'notched_slider',
    tags = { name = slider_tag_name },
    tooltip = params.value,
    value = params.value,
    minimum_value = params.minimum_value,
    maximum_value = params.maximum_value,
    value_step = params.value_step,
  }

  local data = { text = text, slider = slider, key = params.key }
  Gui.set_data(text, data)
  Gui.set_data(slider, data)
end

Public.get_main_frame = function(player)
  local frame = player.gui.screen[main_frame_name]
  if frame and frame.valid then
    return frame
  end

  local data = {}
  local p_settings = get_player_settings(player.index)

  frame = player.gui.screen.add {
    type = 'frame',
    name = main_frame_name,
    direction = 'vertical',
    style = 'frame',
  }
  Gui.set_style(frame, {
    horizontally_stretchable = true,
    vertically_stretchable = true,
    maximal_height = 600,
  })
  Gui.set_data(frame, data)

  do -- Title
    local title_flow = frame.add { type = 'flow', direction = 'horizontal' }
    Gui.set_style(title_flow, { horizontal_spacing = 8, vertical_align = 'center', bottom_padding = 4 })

    label = title_flow.add { type = 'label', caption = 'Logistic Helper', style = 'frame_title' }
    label.drag_target = frame

    Gui.add_dragger(title_flow, frame)

    data.pin = title_flow.add {
      type = 'sprite-button',
      name = pin_button_name,
      sprite = 'lh_pin_white',
      style = 'close_button',
      tooltip = {'gui.pin_settings'},
      auto_toggle = true,
    }

    title_flow.add {
      type = 'sprite-button',
      name = close_button_name,
      sprite = 'utility/close',
      clicked_sprite = 'utility/close_black',
      style = 'close_button',
      tooltip = {'gui.close-instruction'}
    }
  end

  local inner = frame.add { type = 'frame', direction = 'vertical', style = 'inside_shallow_frame' }
  
  do -- Subheader
    local subheader = inner.add { type = 'frame', style = 'subheader_frame' }
    Gui.set_style(subheader, { use_header_filler = true, horizontally_stretchable = true })
    local label = subheader.add { type = 'label', caption = 'Select logistic conditions', style = 'subheader_caption_label' }
    Gui.set_style(label, { font_color = { 200, 200, 200 }, font = 'default-semibold' })
  end

  local canvas =  inner.add { type = 'scroll-pane', direction = 'vertical' }
  Gui.set_style(canvas, { padding = 12 })

  local radio_buttons = {}

  make_setting(canvas, {
    key = 'items',
    state = p_settings.active == 'items',
    caption = 'Items',
    tooltip = {'gui.use_items_tooltip'},
    value = p_settings.items,
    minimum_value = 0, maximum_value = 1000, value_step = 100,
    radio_buttons = radio_buttons,
  })
  canvas.add { type = 'line', direction = 'horizontal' }
  make_setting(canvas, {
    key = 'stacks',
    state = p_settings.active == 'stacks',
    caption = 'Stacks',
    tooltip = {'gui.use_stacks_tooltip'},
    value = p_settings.stacks,
    minimum_value = 0, maximum_value = 48, value_step = 5,
    radio_buttons = radio_buttons,
  })
  canvas.add { type = 'line', direction = 'horizontal' }
  do -- Trash unrequested
    local flow = canvas.add { type = 'flow', direction = 'horizontal' }
    flow.add {
      type = 'checkbox',
      name = trash_not_requested_name,
      state = p_settings.trash_not_requested,
    }
    flow.add {
      type = 'label',
      caption = {'trash-not-requested-items'},
      tooltip = {'trash-not-requested-items-tooltip'},
    }
  end
    do -- Request from buffers
    local flow = canvas.add { type = 'flow', direction = 'horizontal' }
    flow.add {
      type = 'checkbox',
      name = request_from_buffers_name,
      state = p_settings.request_from_buffers,
    }
    flow.add {
      type = 'label',
      caption = {'gui-logistic.request-from-buffer-chests'},
    }
  end
  

  frame.auto_center = true
  return frame
end

Public.toggle_main_frame = function(player)
  if storage.pin[player.index] then
    return
  end

  local frame = player.gui.screen[main_frame_name]
  if frame and frame.visible then
    player.opened = nil
    frame.visible = false
    Gui.get_data(frame).pin.toggled = false
  else
    frame = Public.get_main_frame(player)
    player.opened = frame
    frame.visible = true
  end
end

Gui.on_custom_close(main_frame_name, function(event)
  Public.toggle_main_frame(event.player)
end)

Gui.on_click(close_button_name, function(event)
  storage.pin[event.player_index] = nil
  Public.toggle_main_frame(event.player)
end)

Gui.on_click(pin_button_name, function(event)
  if event.element.toggled then
    storage.pin[event.player_index] = true
  else
    storage.pin[event.player_index] = nil
    local player = event.player
    player.opened = Public.get_main_frame(player)
  end
end)

Gui.on_checked_state_changed(radio_button_name, function(event)
  local element = event.element
  local data = Gui.get_data(element)
  for _, radio in pairs(data.list) do
    radio.state = false
  end
  element.state = true
  get_player_settings(event.player_index).active = data.key
end)

Gui.on_checked_state_changed(trash_not_requested_name, function(event)
  get_player_settings(event.player_index).trash_not_requested = event.element.state
end)

Gui.on_checked_state_changed(request_from_buffers_name, function(event)
  get_player_settings(event.player_index).request_from_buffers = event.element.state
end)

Event.add(defines.events.on_gui_value_changed, function(event)
  local element = event.element
  if not (element and element.valid) then
    return
  end

  local tag = element.tags and element.tags.name
  if not tag or tag ~= slider_tag_name then
    return
  end

  local data = Gui.get_data(element)
  local slider_value = data.slider.slider_value
  data.text.text = tostring(slider_value)
  data.slider.tooltip = string.format(slider_value)
  get_player_settings(event.player_index)[data.key] = slider_value
end)

Event.add(defines.events.on_gui_text_changed, function(event)
  local element = event.element
  if not (element and element.valid) then
    return
  end

  local tag = element.tags and element.tags.name
  if not tag or tag ~= text_tag_name then
    return
  end

  local data = Gui.get_data(element)
  local text_value = tonumber(data.text.text)
  data.slider.slider_value = text_value
  get_player_settings(event.player_index)[data.key] = text_value
end)

return Public
