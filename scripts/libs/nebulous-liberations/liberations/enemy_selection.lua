local Selection = require("scripts/libs/nebulous-liberations/liberations/selection")

---@class Liberation.EnemySelection
---@field instance Liberation.MissionInstance
---@field package selection Liberation._Selection
local EnemySelection = {}

---@return Liberation.EnemySelection
function EnemySelection:new(instance)
  local enemy_selection = {
    instance = instance,
    selection = Selection:new(instance)
  }

  setmetatable(enemy_selection, self)
  self.__index = self

  local INDICATOR_GID = Net.get_tileset(instance.area_id, "/server/assets/tiles/attack indicator.tsx").first_gid

  local function filter(x, y, z)
    local tile = Net.get_tile(instance.area_id, x, y, z)

    return tile.gid > 0
  end

  enemy_selection.selection:set_filter(filter)
  --set indicator may need offset_y to adjust with a z input
  enemy_selection.selection:set_indicator({
    gid = INDICATOR_GID,
    width = 48,
    height = 24,
    offset_x = 1,
    offset_y = 1,
  })

  return enemy_selection
end

-- shape = [m][n] bool array, n being odd, just below bottom center is enemy position
function EnemySelection:set_shape(shape, shape_offset_x, shape_offset_y)
  self.selection:set_shape(shape, shape_offset_x, shape_offset_y)
end

---@param position Net.Position
---@param direction string
function EnemySelection:move(position, direction)
  self.selection:move(position, direction)
end

-- returns players that collide
---@return Liberation.Player[]
function EnemySelection:detect_players()
  local players = {}

  for _, player in ipairs(self.instance.players) do
    local x, y, z = player:position_multi()

    if player.health ~= 0 and self.selection:is_within(x, y, z) then
      players[#players + 1] = player
    end
  end

  return players
end

function EnemySelection:indicate()
  self.selection:indicate()
end

function EnemySelection:remove_indicators()
  -- delete objects
  self.selection:remove_indicators()
end

-- exports
return EnemySelection
