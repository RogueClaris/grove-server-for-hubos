-- enemy implementations are in the enemies folder

---@class Liberation.Enemy
---@field id Net.ActorId
---@field battle_name string
---@field name string? reserved, will automatically be set on creation
---@field is_boss boolean? reserved, will automatically be set on creation
---@field health number
---@field max_health number
---@field x number should be floored, but spawned bots should be centered on tiles (x + .5)
---@field y number should be floored, but spawned bots should be centered on tiles (y + .5)
---@field z number should be floored
---@field mug Net.TextureAnimationPair?
---@field encounter string
---@field is_engaged boolean
---@field new fun(self: Liberation.Enemy, mission: Liberation.MissionInstance, position: Net.Position): Liberation.Enemy
---@field take_turn fun(self: Liberation.Enemy): Net.Promise
---@field get_death_message fun(self: Liberation.Enemy): string
---@field do_first_encounter_banter fun(self: Liberation.Enemy, player_id: Net.ActorId): Net.Promise called when is_engaged is false

local BlizzardMan = require("scripts/libs/nebulous-liberations/liberations/enemies/blizzardman")
local BigBrute = require("scripts/libs/nebulous-liberations/liberations/enemies/bigbrute")
local ShadeMan = require("scripts/libs/nebulous-liberations/liberations/enemies/shademan")
local Bladia = require("scripts/libs/nebulous-liberations/liberations/enemies/bladia")
local ExplodingEffect = require("scripts/libs/nebulous-liberations/utils/exploding_effect")

local Enemy = {}

local name_to_enemy = {
  BlizzardMan = BlizzardMan,
  BigBrute = BigBrute,
  ShadeMan = ShadeMan,
  Bladia = Bladia
}

---@return Liberation.Enemy
function Enemy.from(instance, position, direction, name, rank)
  local enemy = name_to_enemy[name]:new(instance, position, direction, rank)
  enemy.name = enemy.name or name

  Net.set_bot_name(enemy.id, enemy.name .. ": " .. enemy.health)

  return enemy
end

function Enemy.is_alive(enemy)
  if enemy == nil then return false end
  return Net.is_bot(enemy.id)
end

function Enemy.get_death_message()
  return ""
end

---@param instance Liberation.MissionInstance
function Enemy.destroy(instance, enemy)
  return Async.create_promise(function(resolve)
    local success = false
    if not Enemy.is_alive(enemy) then
      -- already died
      return resolve(success)
    end

    -- remove from the instance
    for i, stored_enemy in pairs(instance.enemies) do
      if enemy == stored_enemy then
        table.remove(instance.enemies, i)
        break
      end
    end

    -- begin exploding the enemy
    local explosions = ExplodingEffect:new(enemy.id)

    -- moving every player's camera to the enemy
    local slide_time = .2
    local hold_time = 3
    local extra_explosion_time = .5

    for _, player in ipairs(instance.players) do
      Net.lock_player_input(player.id)

      Net.slide_player_camera(player.id, enemy.x + .5, enemy.y + .5, enemy.z, slide_time)
      Net.move_player_camera(player.id, enemy.x + .5, enemy.y + .5, enemy.z, hold_time)

      Net.slide_player_camera(player.id, player.x, player.y, player.z, slide_time)
      Net.unlock_player_camera(player.id)
    end

    Async.await(Async.sleep(slide_time))

    -- display death message
    local message = enemy:get_death_message()
    local texture_path = enemy.mug and enemy.mug.texture_path
    local animation_path = enemy.mug and enemy.mug.animation_path
    if message ~= nil then
      for _, player_session in ipairs(instance.player_sessions) do
        player_session.player:message(message, texture_path, animation_path)
      end
    end

    Async.await(Async.sleep(hold_time + extra_explosion_time))

    -- remove from the server
    Net.remove_bot(enemy.id)

    Async.await(Async.sleep(extra_explosion_time))

    -- stop explosions
    explosions:remove()

    -- padding time to fix issues with unlock_player_camera
    -- also looks nice with items
    local unlock_padding = .3

    Async.await(Async.sleep(slide_time + unlock_padding))

    -- unlock players who were not locked
    for _, player_session in ipairs(instance.player_sessions) do
      Net.unlock_player_input(player_session.player.id)
    end

    success = true

    return resolve(success)
  end)
end

return Enemy
