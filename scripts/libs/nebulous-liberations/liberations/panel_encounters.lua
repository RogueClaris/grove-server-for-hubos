local PanelEncounters = {}

local corner_offsets = {
  { 1,  -1 },
  { 1,  1 },
  { -1, -1 },
  { -1, 1 },
}

local function has_dark_panel(instance, x, y, z)
  local panel = instance:get_panel_at(x, y, z)
  if not panel then return false end
  local panel_type_table = { "Dark Panel", "Dark Hole", "Indestructible Panel", "Item Panel", "Trap Panel" }
  function includes(table, value)
    for _, v in ipairs(table) do
      if value == v then
        return true
      end
    end
  end

  return includes(panel_type_table, panel.type)
end

---@param instance Liberation.MissionInstance
---@param player Liberation.Player
function PanelEncounters.resolve_terrain(instance, player)
  local x, y, z = player:position_multi()
  local x_left = has_dark_panel(instance, x - 1, y, z)
  local x_right = has_dark_panel(instance, x + 1, y, z)
  local y_left = has_dark_panel(instance, x, y - 1, z)
  local y_right = has_dark_panel(instance, x, y + 1, z)

  if (x_left and x_right) or (y_left and y_right) then
    return "surrounded"
  end

  if (x_left or x_right) and (y_left or y_right) then
    return "disadvantage"
  end

  for _, offset in ipairs(corner_offsets) do
    if has_dark_panel(instance, x + offset[1], y + offset[2], z) then
      return "even"
    end
  end

  return "advantage"
end

return PanelEncounters
