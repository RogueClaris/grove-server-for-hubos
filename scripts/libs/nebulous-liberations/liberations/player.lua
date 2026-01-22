local PlayerSelection = require("scripts/libs/nebulous-liberations/liberations/selections/player_selection")
local Loot = require("scripts/libs/nebulous-liberations/liberations/loot")
local EnemyHelpers = require("scripts/libs/nebulous-liberations/liberations/enemy_helpers")
local ParalysisEffect = require("scripts/libs/nebulous-liberations/liberations/effects/paralysis_effect")
local RecoverEffect = require("scripts/libs/nebulous-liberations/liberations/effects/recover_effect")
local Emotes = require("scripts/libs/emotes")

---@class Liberation.Player
---@field instance Liberation.MissionInstance
---@field id Net.ActorId
---@field health number
---@field max_health number
---@field shadowsteps number
---@field paralysis_effect Liberation.ParalysisEffect?
---@field paralysis_counter number
---@field invincible boolean
---@field completed_turn boolean
---@field selection Liberation._PlayerSelection
---@field ability Liberation.Ability?
---@field disconnected boolean
---@field is_trapped boolean
local Player = {}

---@param instance Liberation.MissionInstance
---@param player_id Net.ActorId
---@return Liberation.Player
function Player:new(instance, player_id)
  local player = {
    instance = instance,
    id = player_id,
    health = 100,
    max_health = 100,
    shadowsteps = {},
    paralysis_effect = nil,
    paralysis_counter = 0,
    invincible = false,
    completed_turn = false,
    selection = PlayerSelection:new(instance, player_id),
    ability = nil,
    disconnected = false,
    is_trapped = false
  }

  setmetatable(player, self)
  self.__index = self
  return player
end

function Player:emote_state()
  if Net.is_player_battling(self.id) then
  elseif self.invincible then
    Net.set_player_emote(self.id, Emotes.GG)
  elseif self.completed_turn then
    Net.set_player_emote(self.id, Emotes.ZZZ)
  else
    Net.set_player_emote(self.id, Emotes.BLANK)
  end
end

local order_points_mug_texture = "/server/assets/NebuLibsAssets/mugs/order pts.png"
local order_points_mug_animations = {
  "/server/assets/NebuLibsAssets/mugs/order pts 0.animation",
  "/server/assets/NebuLibsAssets/mugs/order pts 1.animation",
  "/server/assets/NebuLibsAssets/mugs/order pts 2.animation",
  "/server/assets/NebuLibsAssets/mugs/order pts 3.animation",
  "/server/assets/NebuLibsAssets/mugs/order pts 4.animation",
  "/server/assets/NebuLibsAssets/mugs/order pts 5.animation",
  "/server/assets/NebuLibsAssets/mugs/order pts 6.animation",
  "/server/assets/NebuLibsAssets/mugs/order pts 7.animation",
  "/server/assets/NebuLibsAssets/mugs/order pts 8.animation",
}

function Player:position()
  return Net.get_player_position(self.id)
end

function Player:position_multi()
  return Net.get_player_position_multi(self.id)
end

---@param message string
---@param texture_path? string
---@param animation_path? string
function Player:message(message, texture_path, animation_path)
  return Async.message_player(self.id, message, texture_path, animation_path)
end

---@param message string
---@param close_delay number
---@param texture_path? string
---@param animation_path? string
function Player:message_auto(message, close_delay, texture_path, animation_path)
  return Async.message_player_auto(self.id, message, close_delay, texture_path, animation_path)
end

---@param message string
function Player:message_with_mug(message)
  local mug = Net.get_player_mugshot(self.id)
  return self:message(message, mug.texture_path, mug.animation_path)
end

---@param question string
---@param texture_path? string
---@param animation_path? string
function Player:question(question, texture_path, animation_path)
  return Async.question_player(self.id, question, texture_path, animation_path)
end

---@param question string
function Player:question_with_mug(question)
  local mug = Net.get_player_mugshot(self.id)
  return self:question(question, mug.texture_path, mug.animation_path)
end

---@param a string
---@param b? string
---@param c? string
---@param texture_path? string
---@param animation_path? string
function Player:quiz(a, b, c, texture_path, animation_path)
  return Async.quiz_player(self.id, a, b, c, texture_path, animation_path)
end

---@param message string
function Player:message_with_points(message)
  local mug_animation = order_points_mug_animations[self.instance.order_points + 1]
  return self:message(message, order_points_mug_texture, mug_animation)
end

---@param question string
function Player:question_with_points(question)
  local mug_animation = order_points_mug_animations[self.instance.order_points + 1]
  return self:question(question, order_points_mug_texture, mug_animation)
end

---@param a string
---@param b? string
---@param c? string
function Player:quiz_with_points(a, b, c)
  local mug_animation = order_points_mug_animations[self.instance.order_points + 1]
  return self:quiz(a, b, c, order_points_mug_texture, mug_animation)
end

function Player:get_ability_permission()
  local question_promise = self:question_with_mug(self.ability.question)

  question_promise.and_then(function(response)
    if response == 0 then
      -- No
      self.selection:clear()
      Net.unlock_player_input(self.id)
      return
    end

    -- Yes
    if self.instance.order_points < self.ability.cost then
      -- not enough order points
      self:message("Not enough Order Pts!")
      return
    end

    self.instance.order_points = self.instance.order_points - self.ability.cost
    self.ability.activate(self.instance, self)
  end)
end

function Player:get_pass_turn_permission()
  local question = "End without doing anything?"

  if self.health < self.max_health then
    question = "Recover HP?"
  end

  local question_promise = self:question_with_mug(question)

  question_promise.and_then(function(response)
    if response == 0 then
      -- No
      Net.unlock_player_input(self.id)
    elseif response == 1 then
      -- Yes
      self:pass_turn()
    end
  end)
end

function Player:initiate_encounter(encounter_path, data)
  return Async.create_scope(function()
    local results = Async.await(Async.initiate_encounter(self.id, encounter_path, data))

    if results == nil then
      return
    end

    local total_enemy_health = 0

    for _, enemy in ipairs(results.enemies) do
      total_enemy_health = total_enemy_health + enemy.health
    end

    self.health = results.health

    Net.set_player_health(self.id, self.health)

    Net.set_player_emotion(self.id, results.emotion)

    if self.health == 0 then
      self:paralyze()
    end

    if total_enemy_health > 0 or results.ran then
      results.success = false
    else
      results.success = true
    end

    return results
  end)
end

function Player:heal(amount)
  return Async.create_promise(function(resolve)
    local previous_health = self.health

    self.health = math.min(math.ceil(self.health + amount), self.max_health)

    Net.set_player_health(self.id, self.health)

    if previous_health < self.health then
      RecoverEffect:new(self.id):remove()
    end

    return resolve(Async.sleep(0.5))
  end)
end

function Player:hurt(amount)
  if self.invincible or self.health == 0 or amount <= 0 then
    return
  end

  Net.play_sound_for_player(self.id, "/server/assets/NebuLibsAssets/sound effects/hurt.ogg")

  self.health = math.max(math.ceil(self.health - amount), 0)

  Net.set_player_health(self.id, self.health)

  if self.health == 0 then
    Async.sleep(1).and_then(function()
      self:paralyze()
    end)
  end
end

function Player:paralyze()
  self.paralysis_counter = 2
  self.paralysis_effect = ParalysisEffect:new(self.id)
  self.is_trapped = true
end

function Player:pass_turn()
  -- heal up to 50% of health
  Async.await(self:heal(self.max_health / 2)).and_then(function()
    self:complete_turn()
  end)
end

function Player:complete_turn()
  if self.disconnected then
    return
  end

  self.completed_turn = true
  self.selection:clear()

  self:emote_state()

  if self.instance.ready_count < #self.instance.players then
    Net.unlock_player_camera(self.id)
  end

  self.instance.ready_count = self.instance.ready_count + 1
end

function Player:give_turn()
  self.invincible = false

  if self.paralysis_counter > 0 then
    self.paralysis_counter = self.paralysis_counter - 1

    if self.paralysis_counter > 0 then
      -- still paralyzed
      self:complete_turn()
      return
    end

    -- release
    self.paralysis_effect:remove()
    self.paralysis_effect = nil

    -- heal 50% so we don't just start battles with 0 lol
    if not self.is_trapped then
      self:heal(self.max_health / 2)
    else
      self.is_trapped = false
    end
  end

  self.completed_turn = false
  Net.unlock_player_input(self.id)
end

function Player:find_closest_guardian()
  local closest_guardian
  local closest_distance = math.huge

  local x, y, z = self:position_multi()

  for _, enemy in ipairs(self.instance.enemies) do
    if enemy.is_boss then
      goto continue
    end

    local distance = EnemyHelpers.chebyshev_tile_distance(enemy, x, y, z)

    if distance < closest_distance then
      closest_distance = distance
      closest_guardian = enemy
    end

    ::continue::
  end

  return closest_guardian
end

function Player:liberate_panels(panels, results)
  return Async.create_scope(function()
    -- Allow time for the player to see the liberation range
    Async.await(Async.sleep(2))

    -- If the results do not exist, notify the player of the issue to start a bug report.
    if results == nil then
      Async.await(self:message_with_mug("Something's wrong!\nThere's no results!")).and_then(function()
        Async.await(self:message_with_mug("Please report this!"))
      end)
    else
      -- Message based on the results.
      if results.success == false then
        Async.await(self:message_with_mug("Oh, no!\nLiberation failed!"))
      elseif results.turns == 1 then
        Async.await(self:message_with_mug("One turn liberation!"))
      else
        Async.await(self:message_with_mug("Yeah!\nI liberated it!"))
      end
    end
  end)
end

-- returns a promise that resolves after looting
function Player:loot_panels(panels, remove_traps, destroy_items)
  return Async.create_scope(function()
    for _, panel in ipairs(panels) do
      if panel.loot then
        -- loot the panel if it has loot
        Async.await(Loot.loot_item_panel(self.instance, self, panel, destroy_items))
      elseif panel.type == "Trap Panel" then
        local slide_time = .1
        local spawn_x = math.floor(panel.x) + .5
        local spawn_y = math.floor(panel.y) + .5
        local spawn_z = panel.z

        Net.slide_player_camera(
          self.id,
          spawn_x,
          spawn_y,
          spawn_z,
          slide_time
        )

        Async.await(Async.sleep(slide_time))

        if remove_traps then
          Async.await(self:message_with_mug("I found a trap! It's been removed."))
        elseif panel.custom_properties["Damage Trap"] == "true" then
          if panel.custom_properties["Trap Message"] ~= nil then
            Async.await(self:message_with_mug(panel.custom_properties["Trap Message"]))
          else
            Async.await(self:message_with_mug("Ah! A damage trap!"))
          end
          self:hurt(tonumber(panel.custom_properties["Damage Dealt"]))
        elseif panel.custom_properties["Stun Trap"] == "true" then
          if panel.custom_properties["Trap Message"] ~= nil then
            Async.await(self:message_with_mug(panel.custom_properties["Trap Message"]))
          else
            Async.await(self:message_with_mug("Ah! A paralysis trap!"))
          end
          self:paralyze()
        end
      end
      -- Remove that panel.
      self.instance:remove_panel(panel)
    end

    -- Clear the selection so that it can be used again later.
    self.selection:clear()

    return true;
  end)
end

function Player:liberate_and_loot_panels(panels, results, remove_traps, destroy_items)
  return Async.create_scope(function()
    self:liberate_panels(panels, results).and_then(function()
      self:loot_panels(panels, remove_traps, destroy_items).and_then(function()
        self:complete_turn()
      end)
    end)
  end)
end

function Player:handle_disconnect()
  self.selection:clear()

  if self.completed_turn then
    self.instance.ready_count = self.instance.ready_count - 1
  end

  if self.paralysis_effect then
    self.paralysis_effect:remove()
  end

  self.disconnected = true
end

-- export
return Player
