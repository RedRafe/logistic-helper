local select_mode = function(color, cursor_box)
  return {
    border_color = color,
    cursor_box_type = cursor_box,
    mode = {
      'same-force',
      'buildable-type',
      'entity-ghost',
    },
    entity_filter_mode = 'whitelist',
    entity_type_filters = {
      'assembling-machine',
      'inserter',
      'logistic-container',
    },
  }
end

data:extend({
  {
    action = 'lua',
    key_sequence = 'CONTROL + L',
    alternative_key_sequence = '',
    name = 'get_logistic_helper_tool',
    type = 'custom-input',
  },
  {
    action = 'lua',
    associated_control_input = 'get_logistic_helper_tool',
    icon = '__logistic-helper__/graphics/helper.png',
    disabled_icon = '__logistic-helper__/graphics/helper_white.png',
    icon_size = 256,
    name = 'get_logistic_helper_tool',
    small_icon = '__logistic-helper__/graphics/helper.png',
    disabled_small_icon = '__logistic-helper__/graphics/helper_white.png',
    small_icon_size = 256,
    type = 'shortcut',
  },
  {
    type = 'selection-tool',
    name = 'logistic_helper_tool',
    icons = {
      { icon = '__logistic-helper__/graphics/black.png', icon_size = 1, scale = 64 },
      { icon = '__logistic-helper__/graphics/helper_white.png', icon_size = 256, scale = 0.18 }
    },
    flags = {
      'not-stackable',
      'spawnable',
      'only-in-cursor',
      --'draw-logistic-overlay',
    },
    style = 'blue',
    stack_size = 1,
    hidden = true,
    always_include_tiles = false,
    select = select_mode({ 0, 250, 154 }, 'entity'),
    alt_select = select_mode({ 0, 250, 154 }, 'entity'),
    reverse_select = select_mode({ 255, 127, 80 }, 'not-allowed'),
    alt_reverse_select = select_mode({ 255, 127, 80 }, 'not-allowed'),
  },
})

local function make_gui_sprite(name, size, p)
  local sprite = {
    type = 'sprite',
    name = 'lh_'..name,
    filename = '__logistic-helper__/graphics/'..name..'.png',
    size = size or 64,
    flags = { 'gui-icon' },
  }
  for k, v in pairs(p or {}) do
    sprite[k] = v
  end
  return sprite
end

data:extend({
  make_gui_sprite('pin'),
  make_gui_sprite('pin_white'),
})