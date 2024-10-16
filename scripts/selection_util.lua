local insert = table.insert

local Public = {}

--- @class LogisticUnit
--- @field machines
--- @field input_inserters
--- @field output_inserters
--- @field input_containers
--- @field output_containers

local function clear_inserter(entity)
  local cb = entity.get_or_create_control_behavior()
  cb.circuit_condition = nil
  cb.circuit_enable_disable = false
  cb.circuit_hand_read_mode = defines.control_behavior.inserter.hand_read_mode.hold
  cb.circuit_read_hand_contents = false
  cb.circuit_set_filters = false
  cb.circuit_set_stack_size = false
  cb.circuit_stack_control_signal = nil
  cb.connect_to_logistic_network = false
  cb.logistic_condition = nil
end

local function clear_assembler(entity)
  local cb = entity.get_or_create_control_behavior()
  cb.circuit_condition = nil
  cb.circuit_enable_disable = false
  cb.circuit_read_contents = false
  cb.circuit_read_ingredients = false
  cb.circuit_read_recipe_finished = false
  cb.circuit_read_working = false
  cb.circuit_recipe_finished_signal = nil
  cb.circuit_set_recipe = false
  cb.circuit_working_signal = nil
  cb.connect_to_logistic_network = false
  cb.logistic_condition = nil
end

local function clear_container(entity)
  local mode = entity.prototype.logistic_mode
  if mode == 'storage' then
    entity.set_filter(1, nil)
  elseif mode == 'buffer' or mode == 'requester' then
    local lp = entity.get_logistic_point(defines.logistic_member_index.logistic_container)
    for i = 1, lp.sections_count do
      lp.remove_section(i)
      lp.trash_not_requested = true
      if mode == 'requester' then
        entity.request_from_buffers = true
      end
    end
  end
end

local function clear_entity_info(entity)
  local e_type = (entity.type ~= 'entity-ghost' and entity.type) or entity.ghost_type
  if e_type == 'assembling-machine' then
    clear_assembler(entity)
  elseif e_type == 'inserter' then
    clear_inserter(entity)
  elseif e_type == 'logistic-container' then
    clear_container(entity)
  end
end

local function collide(entity, position)
  local lt = entity.selection_box.left_top
  local rb = entity.selection_box.right_bottom
  return (lt.x < position.x and rb.x > position.x) and (lt.y < position.y and rb.y > position.y)
end

local function build_logistic_units(entities)
  local inserters = {}
  local containers = {}
  local machines = {}
  local units = {}

  for _, e in pairs(entities) do
    local e_type = (e.type ~= 'entity-ghost' and e.type) or e.ghost_type
    if e_type == 'assembling-machine' then
      local recipe, quality = e.get_recipe()
      machines[#machines + 1] = e
    elseif e_type == 'inserter' then
      inserters[#inserters + 1] = e
    elseif e_type == 'logistic-container' then
      containers[#containers + 1] = e
    end
  end

  -- Creating groups
  for _, m in pairs(machines) do
    local recipe, quality = m.get_recipe()
    if recipe then
      local group = {
        recipe = recipe,
        quality = quality,
        machines = { m },
        input_inserters = {},
        output_inserters = {},
        input_containers = {},
        output_containers = {},
      }
      -- find all inserters
      for _, i in pairs(inserters) do
        if collide(m, i.drop_position) then
          insert(group.input_inserters, i)
        elseif collide(m, i.pickup_position) then
          insert(group.output_inserters, i)
        end
      end
      -- find all chests
      for _, c in pairs(containers) do
        for _, i in pairs(group.input_inserters) do
          if collide(c, i.pickup_position) then
            insert(group.input_containers, c)
          end
        end
        for _, i in pairs(group.output_inserters) do
          if collide(c, i.drop_position) then
            insert(group.output_containers, c)
          end
        end
      end
      insert(units, group)
    end
  end

  return units
end

local function compute_group_conditions(group, player_settings)
  local recipe = group.recipe
  local quality = (group.quality and group.quality.name) or group.quality or 'normal'
  local main_product = false

  -- Main product
  if #recipe.products == 1 then
    if recipe.products[1].type == 'item' then
      main_product = recipe.products[1].name
    end
  else
    local proto = prototypes.recipe[recipe.name]
    if proto and proto.main_product and proto.main_product.type == 'item' then
      main_product = proto.main_product.name
    end
  end

  if not main_product then
    return
  end

  local amount = player_settings.items
  if player_settings.active == 'stacks' then
    amount = prototypes.item[main_product].stack_size * player_settings.stacks
  end

  -- Inputs
  local requests = {}
  for _, i in pairs(recipe.ingredients) do
    if i.type == 'item' then
      requests[#requests + 1] = { name = i.name, count = prototypes.item[i.name].stack_size, quality = quality }
    end
  end
  for _, c in pairs(group.input_containers) do
    if c.prototype.logistic_mode == 'requester' or c.prototype.logistic_mode == 'buffer' then
      local lp = c.get_logistic_point(defines.logistic_member_index.logistic_container)
      local section = lp.add_section()
      for slot_index, r in pairs(requests) do
        section.set_slot(slot_index, { value = { type = 'item', name = r.name, quality = quality, comparator = '=' }, min = r.count })
      end
    end
  end

  -- Outputs
  for _, i in pairs(group.output_inserters) do
    local cb = i.get_or_create_control_behavior()
    cb.logistic_condition = {
      comparator = '<',
      first_signal = { type = 'item', name = main_product, quality = quality },
      constant = amount,
    }
    cb.connect_to_logistic_network = true
  end
  for _, c in pairs(group.output_containers) do
    if c.prototype.logistic_mode == 'storage' then
      c.storage_filter = { name = main_product, type = 'item', quality = quality }
    elseif c.prototype.logistic_mode == 'buffer' then
      local lp = c.get_logistic_point(defines.logistic_member_index.logistic_container)
      local section = lp.add_section()
      section.set_slot(1, { value = { type = 'item', name = main_product, quality = quality, comparator = '=' }, min = 1e7 })
    end
  end
end

--- @param entities table<LuaEntity>
--- @param player_settings table
Public.set_info = function(entities, player_settings)
  local units = build_logistic_units(entities)
  for _, group in pairs(units) do
    for _, subgroup in pairs(group) do
      if type(subgroup) == 'table' then
        for _, entity in pairs(subgroup) do
          clear_entity_info(entity)
        end
      end
    end
  end
  for _, group in pairs(units) do
    compute_group_conditions(group, player_settings)
  end
end

--- @param entities table<LuaEntity>
Public.remove_info = function(entities)
  for _, entity in pairs(entities) do
    clear_entity_info(entity)
  end
end

return Public
