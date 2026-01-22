local EnemySelection = require("scripts/libs/nebulous-liberations/liberations/enemy_selection")
local EnemyHelpers = require("scripts/libs/nebulous-liberations/liberations/enemy_helpers")
local Preloader = require("scripts/libs/nebulous-liberations/liberations/preloader")

Preloader.add_asset("/server/assets/NebuLibsAssets/bots/snowball.png")
Preloader.add_asset("/server/assets/NebuLibsAssets/bots/snowball.animation")

---@class Liberation.Enemies.BlizzardMan: Liberation.Enemy
---@field instance Liberation.MissionInstance
---@field selection Liberation.EnemySelection
---@field damage number
---@field direction string
local BlizzardMan = {}

--Setup ranked health and damage
local rank_to_index = {
  V1 = 1,
  V2 = 2,
  V3 = 3,
  SP = 4,
  Alpha = 2,
  Beta = 3,
  Omega = 4,
}

local mob_health = { 400, 1200, 1600, 2000 }
local mob_damage = { 40, 80, 120, 160 }
local mob_ranks = { 0, 1, 2, 3 }

---@return Liberation.Enemies.BlizzardMan
function BlizzardMan:new(instance, position, direction, rank)
  local rank_index = rank_to_index[rank]

  local blizzardman = {
    instance = instance,
    id = nil,
    health = mob_health[rank_index],
    max_health = mob_health[rank_index],
    damage = mob_damage[rank_index],
    rank = mob_ranks[rank_index],
    x = math.floor(position.x),
    y = math.floor(position.y),
    z = math.floor(position.z),
    mug = {
      texture_path = "/server/assets/NebuLibsAssets/mugs/blizzardman.png",
      animation_path = "/server/assets/NebuLibsAssets/mugs/blizzardman.animation",
    },
    encounter = "/server/assets/NebuLibsAssets/encounters/BigBrute.zip",
    selection = EnemySelection:new(instance),
    is_engaged = false
  }

  setmetatable(blizzardman, self)
  self.__index = self

  local shape = {
    { 1, 1, 1 },
    { 1, 0, 1 },
    { 1, 1, 1 },
    { 1, 1, 1 }
  }

  blizzardman.selection:set_shape(shape, 0, -2)
  blizzardman:spawn(direction)

  return blizzardman
end

function BlizzardMan:do_first_encounter_banter(player_id)
  return Async.create_scope(function()
    Async.await(Async.message_player(player_id, "I didn't think you would make it this far! *Whoosh*",
      self.mug.texture_path, self.mug.animation_path))
    Async.await(Async.message_player(player_id, "I'll freeze you to the bone!", self.mug.texture_path,
      self.mug.animation_path))
    self.is_engaged = true
  end)
end

function BlizzardMan:spawn(direction)
  self.id = Net.create_bot({
    texture_path = "/server/assets/NebuLibsAssets/bots/blizzardman.png",
    animation_path = "/server/assets/NebuLibsAssets/bots/blizzardman.animation",
    area_id = self.instance.area_id,
    direction = direction,
    warp_in = false,
    x = self.x + .5,
    y = self.y + .5,
    z = self.z
  })
  Net.set_bot_map_color(self.id, EnemyHelpers.boss_minimap_color)
end

function BlizzardMan:get_death_message()
  return "Woosh!\nI can't believe\nit. I can't lose.\nNOOOO!"
end

function BlizzardMan:take_turn()
  return Async.create_scope(function()
    if not debug and self.instance.phase == 1 then
      for _, player in ipairs(self.instance.players) do
        player:message_auto(
          "I'll turn this area into a Nebula ski resort! Got it?",
          2,
          self.mug.texture_path,
          self.mug.animation_path
        )
      end
    end

    self.selection:move(self, Net.get_bot_direction(self.id))

    local caught_players = self.selection:detect_players()

    if #caught_players == 0 then
      return
    end

    self.selection:indicate()

    Async.await(Async.sleep(1))

    for _, player in ipairs(self.instance.players) do
      player:message(
        "Shiver in my\ndeep winter!\nSnowball!",
        self.mug.texture_path,
        self.mug.animation_path
      )
    end

    Async.await(Async.sleep(1))

    EnemyHelpers.play_attack_animation(self)

    local spawned_bots = {}

    for _, player in ipairs(caught_players) do
      local player_x, player_y, player_z = player:position_multi()
      local snowball_bot_id = Net.create_bot({
        texture_path = "/server/assets/NebuLibsAssets/bots/snowball.png",
        animation_path = "/server/assets/NebuLibsAssets/bots/snowball.animation",
        area_id = self.instance.area_id,
        warp_in = false,
        x = player_x - .5,
        y = player_y - .5,
        z = player_z + 8
      })

      Net.animate_bot_properties(snowball_bot_id, {
        {
          properties = {
            { property = "Animation", value = "FALL" },
          }
        },
        {
          properties = {
            { property = "Z", ease = "Linear", value = player_z + 1 },
          },
          duration = .5
        }
      })

      spawned_bots[#spawned_bots + 1] = snowball_bot_id
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
  end)
end

return BlizzardMan
