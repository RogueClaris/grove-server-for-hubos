local EnemyHelpers = require("scripts/libs/nebulous-liberations/liberations/enemy_helpers")
local EnemySelection = require("scripts/libs/nebulous-liberations/liberations/enemy_selection")
local Preloader = require("scripts/libs/nebulous-liberations/liberations/preloader")
local Direction = require("scripts/libs/direction")

Preloader.add_asset("/server/assets/NebuLibsAssets/bots/beast breath.png")
Preloader.add_asset("/server/assets/NebuLibsAssets/bots/beast breath.animation")

local BigBrute = {}

--Setup ranked health and damage
local mob_health = { 120, 180, 220, 250, 300, 360 }
local mob_damage = { 30, 60, 90, 130, 170, 200 }
local mob_ranks = { 0, 0, 0, 0, 0, 0 }

function BigBrute:new(instance, position, direction, rank)
  rank = rank or 1

  local bigbrute = {
    instance = instance,
    id = nil,
    battle_name = "BigBrute",
    health = mob_health[rank],
    max_health = mob_health[rank],
    damage = mob_damage[rank],
    rank = mob_ranks[rank],
    x = math.floor(position.x),
    y = math.floor(position.y),
    z = math.floor(position.z),
    selection = EnemySelection:new(instance),
    encounter = "/server/mods/BigBrute",
    is_engaged = false
  }

  setmetatable(bigbrute, self)
  self.__index = self

  local shape = {
    { 1, 1, 1 },
    { 1, 0, 1 },
    { 1, 1, 1 }
  }

  bigbrute.selection:set_shape(shape, 0, -2)
  bigbrute:spawn(direction)

  return bigbrute
end

function BigBrute:spawn(direction)
  self.id = Net.create_bot({
    texture_path = "/server/assets/NebuLibsAssets/bots/bigbrute.png",
    animation_path = "/server/assets/NebuLibsAssets/bots/bigbrute.animation",
    area_id = self.instance.area_id,
    direction = direction,
    warp_in = false,
    x = self.x + .5,
    y = self.y + .5,
    z = self.z
  })
  Net.set_bot_map_color(self.id, EnemyHelpers.guardian_minimap_marker)
end

function BigBrute.get_death_message(self)
  return "Gyaaaaahh!!"
end

local function sign(a)
  if a < 0 then
    return -1
  end

  return 1
end

local function find_offset(self, xstep, ystep, limit)
  local offset = 0
  -- adding them, as only one should be set, and the other should be set to 0
  local step = math.abs(xstep + ystep)

  for i = limit, 1, -step do
    if EnemyHelpers.can_move_to(self.instance, self.x + xstep * i, self.y + ystep * i, self.z) then
      offset = step * i
      break
    end
  end

  return offset
end

local function attempt_axis_move(self, player, diff, xfilter, yfilter)
  return Async.create_promise(function(resolve)
    local step = sign(diff)
    local limit = math.min(math.abs(diff), 2)
    local offset = find_offset(self, step * xfilter, step * yfilter, limit)

    if offset == 0 then
      return resolve(false)
    end

    local targetx = self.x + step * offset * xfilter
    local targety = self.y + step * offset * yfilter

    EnemyHelpers.face_position(self, targetx + .5, targety + .5)

    local target_direction = Direction.diagonal_from_offset(
      player.x - (targetx + .5),
      player.y - (targety + .5)
    )

    EnemyHelpers.move(self.instance, self, targetx, targety, self.z, target_direction).and_then(function()
      return resolve(true)
    end)
  end)
end

local function attempt_move(self)
  return Async.create_promise(function(resolve)
    local player = EnemyHelpers.find_closest_player(self.instance, self, 4)

    local success = false

    if player == nil then
      -- all players left
      return resolve(success)
    end

    -- local distance = EnemyHelpers.chebyshev_tile_distance(self, player.x, player.y, player.z)

    -- if distance > 4 then
    --   -- too far to target
    --   resolve(false)
    --   return
    -- end

    local player_x, player_y = player:position_multi()
    local xdiff = math.floor(player_x) - self.x
    local ydiff = math.floor(player_y) - self.y

    if (ydiff == 0 or math.abs(xdiff) < math.abs(ydiff)) and xdiff ~= 0 then
      -- travel along the x axis
      success = Async.await(attempt_axis_move(self, player, xdiff, 1, 0))
      if not success then
        -- failed, try the other axis
        success = Async.await(attempt_axis_move(self, player, ydiff, 0, 1))
      end
    elseif ydiff ~= 0 then
      -- travel along the y axis
      success = Async.await(attempt_axis_move(self, player, ydiff, 0, 1))
      if not success then
        -- failed, try the other axis
        success = Async.await(attempt_axis_move(self, player, xdiff, 1, 0))
      end
    end

    return resolve(success)
  end)
end

local function attempt_attack(self)
  return Async.create_promise(function(resolve)
    self.selection:move(self, Net.get_bot_direction(self.id))

    local caught_players = self.selection:detect_players()

    if #caught_players == 0 then
      return resolve(false)
    end

    local closest_player = EnemyHelpers.find_closest_player(self.instance, self)

    if closest_player ~= nil then
      local x, y = closest_player:position_multi()
      EnemyHelpers.face_position(self, x, y)
    end

    self.selection:indicate()

    Async.await(Async.sleep(1))

    EnemyHelpers.play_attack_animation(self)

    local spawned_bots = {}

    for _, player in ipairs(caught_players) do
      local player = player.player

      table.insert(spawned_bots, Net.create_bot({
        texture_path = "/server/assets/NebuLibsAssets/bots/beast breath.png",
        animation_path = "/server/assets/NebuLibsAssets/bots/beast breath.animation",
        animation = "ANIMATE",
        area_id = self.instance.area_id,
        warp_in = false,
        x = player.x + (1 / 32),
        y = player.y + (1 / 32),
        z = player.z
      }))
    end

    Async.await(Async.sleep(.5))

    for _, player in ipairs(self.instance.players) do
      Net.shake_player_camera(player.id, 2, .5)
    end

    for _, player in ipairs(caught_players) do
      player:hurt(self.damage)
    end

    Async.await(Async.sleep(.5))

    for _, bot_id in ipairs(spawned_bots) do
      Net.remove_bot(bot_id, false)
    end

    Async.await(Async.sleep(1))

    self.selection:remove_indicators()

    return resolve(true)
  end)
end

function BigBrute:take_turn()
  return Async.create_scope(function()
    local success = Async.await(attempt_move(self))
    if success == true then
      Async.await(attempt_attack(self))
    end
  end)
end

return BigBrute
