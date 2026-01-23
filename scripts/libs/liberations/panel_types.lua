local PanelTypes = {
  DARK = "Dark Panel",
  DARK_HOLE = "Dark Hole",
  BONUS = "Bonus Panel",
  TRAP = "Trap Panel",
  ITEM = "Item Panel",
  GATE = "Gate Panel",
  INDESTRUCTIBLE = "Indestructible Panel",
}

---Adds values as keys,
---allowing us to use list[value] to test if the values is in the list
local function add_values_as_keys(list)
  for _, value in ipairs(list) do
    list[value] = true
  end

  return list
end

-- generate a list of all panel types
local ALL = {}

for _, value in pairs(PanelTypes) do
  ALL[#ALL + 1] = value
end

PanelTypes.ALL = add_values_as_keys(ALL)

PanelTypes.ENEMY_WALKABLE = add_values_as_keys({
  PanelTypes.DARK,
  PanelTypes.ITEM,
  PanelTypes.TRAP,
})

PanelTypes.LIBERATABLE = add_values_as_keys({
  PanelTypes.DARK,
  PanelTypes.DARK_HOLE,
  PanelTypes.BONUS,
  PanelTypes.ITEM,
  PanelTypes.TRAP,
})

PanelTypes.ABILITY_ACTIONABLE = add_values_as_keys({
  PanelTypes.DARK,
  PanelTypes.ITEM,
  PanelTypes.TRAP,
})

PanelTypes.TERRAIN = add_values_as_keys({
  PanelTypes.DARK,
  PanelTypes.DARK_HOLE,
  PanelTypes.ITEM,
  PanelTypes.INDESTRUCTIBLE,
  PanelTypes.TRAP,
})

PanelTypes.OPTIONAL_COLLISION = add_values_as_keys({
  PanelTypes.DARK,
  PanelTypes.ITEM,
  PanelTypes.TRAP,
})

return PanelTypes
