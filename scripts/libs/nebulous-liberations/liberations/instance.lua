local Player = require("scripts/libs/nebulous-liberations/liberations/player")
local Enemy = require("scripts/libs/nebulous-liberations/liberations/enemy")
local EnemyHelpers = require("scripts/libs/nebulous-liberations/liberations/enemy_helpers")
local PanelEncounters = require("scripts/libs/nebulous-liberations/liberations/panel_encounters")
local Loot = require("scripts/libs/nebulous-liberations/liberations/loot")
local PanelTypes = require("scripts/libs/nebulous-liberations/liberations/panel_types")
local TargetPhase = require("scripts/libs/nebulous-liberations/liberations/target_phase")
local Preloader = require("scripts/libs/nebulous-liberations/liberations/preloader")

local compression = require('scripts/custom-scripts/compression')

local DEBUG_AUTO_WIN = true

-- private functions

local function is_adjacent(position_a, position_b)
  if position_a.z ~= position_b.z then
    return false
  end

  local x_diff = math.abs(math.floor(position_a.x) - math.floor(position_b.x))
  local y_diff = math.abs(math.floor(position_a.y) - math.floor(position_b.y))

  return x_diff + y_diff == 1
end

local function boot_player(player, is_victory, map_name)
  Net.unlock_player_input(player.id)
  compression.decompress(player.id)
  player:boot_to_lobby(is_victory, map_name)
end

---@param self Liberation.MissionInstance
local function liberate(self)
  self.liberated = true

  for _, layer in pairs(self.panels) do
    for _, row in pairs(layer) do
      for _, panel in pairs(row) do
        if panel then
          Net.remove_object(self.area_id, panel.id)
          Net.remove_object(self.area_id, panel.visual_object_id)
        end
      end
    end
  end

  self.panels = {}
  self.dark_holes = {}

  for _, enemy in ipairs(self.enemies) do
    Net.remove_bot(enemy.id, false)
  end

  self.enemies = {}

  local area_properties = Net.get_area_custom_properties(self.area_id)

  Net.set_background(
    self.area_id,
    area_properties["Background Texture"],
    area_properties["Background Animation"],
    tonumber(area_properties["Background Vel X"]),
    tonumber(area_properties["Background Vel Y"])
  )

  if area_properties["Victory Song"] ~= nil then
    Net.set_music(self.area_id, area_properties["Victory Song"])
  else
    Net.set_music(self.area_id, area_properties["Song"])
  end

  local victory_message =
      self.area_name .. " Liberated\n" ..
      "Target: " .. self.target_phase:calculate() .. "\n" ..
      "Actual: " .. self.phase

  for _, player in ipairs(self.players) do
    player:message(victory_message).and_then(function()
      boot_player(player)
    end)
  end
end

local DARK_HOLE_SHAPE = {
  { 1, 1, 1 },
  { 1, 1, 1 },
  { 1, 1, 1 },
}

-- expects execution in a coroutine
---@param self Liberation.MissionInstance
local function convert_indestructible_panels(self)
  local slide_time = .5
  local hold_time = 2

  -- notify players
  for _, player in ipairs(self.players) do
    player:message("No more DarkHoles! Nothing will save the Darkloids now!")
    local player_x, player_y, player_z = player:position_multi()

    Net.lock_player_input(player.id)

    Net.slide_player_camera(player.id, self.boss.x, self.boss.y, self.boss.z, slide_time)

    -- hold the camera
    Net.move_player_camera(player.id, self.boss.x, self.boss.y, self.boss.z, hold_time)

    -- return the camera
    Net.slide_player_camera(player.id, player_x, player_y, player_z, slide_time)
    Net.unlock_player_camera(player.id)
  end

  Async.await(Async.sleep(slide_time + hold_time / 2))

  -- convert panels
  for _, panel in ipairs(self.indestructible_panels) do
    local dark_gids = self.panel_gid_map[PanelTypes.DARK]

    panel.data.gid = dark_gids[math.random(#dark_gids)]
    Net.set_object_data(self.area_id, panel.id, panel.data)
  end

  self.indestructible_panels = {}

  Async.await(Async.sleep(hold_time / 2 + slide_time))

  -- returning control
  for _, player in ipairs(self.players) do
    if not player.completed_turn then
      Net.unlock_player_input(player.id)
    end
  end
end

---@param self Liberation.MissionInstance
---@param player Liberation.Player
local function liberate_panel(self, player)
  return Async.create_scope(function()
    local player = player
    local selection = player.selection
    local panel = selection.root_panel

    if panel.type == PanelTypes.BONUS then
      if panel.custom_properties["Message"] ~= nil then
        Async.await(player:message_with_mug(panel.custom_properties["Message"]))
      else
        Async.await(player:message_with_mug("A BonusPanel! What's it hiding?"))
      end

      self:remove_panel(panel)

      selection:clear()

      Async.await(Loot.loot_bonus_panel(self, player, panel))

      Net.unlock_player_input(player.id)
    else
      if panel.custom_properties["Message"] ~= nil then
        Async.await(player:message_with_mug(panel.custom_properties["Message"]))
      elseif panel.type == PanelTypes.DARK_HOLE then
        Async.await(player:message_with_mug("A Dark Hole! Begin liberation!"))
      else
        Async.await(player:message_with_mug("Let's do it! Liberate panels!"))
      end

      local encounter_path = panel.custom_properties["Encounter"] or self.default_encounter
      local data = {
        terrain = PanelEncounters.resolve_terrain(self, player),
      }

      -- Obtain enemy
      local enemy = self:get_enemy_at(panel.x, panel.y, panel.z)

      -- If an overworld enemy exists, set facing & data
      if enemy then
        local player_x, player_y = player:position_multi()

        EnemyHelpers.face_position(enemy, player_x, player_y)
        encounter_path = enemy.encounter
        data.health = enemy.health
        data.rank = enemy.rank

        -- Boss check for banter
        if enemy.is_boss and not enemy.is_engaged then
          Async.await(enemy:do_first_encounter_banter(player.id))
        end
      elseif panel.enemy then
        -- hidden enemy within dark panel
        local hidden_enemy = panel.enemy
        -- spawn fully healed
        data.health = hidden_enemy.max_health
        -- override encounter
        encounter_path = hidden_enemy.encounter
      end

      ---@type (Net.BattleResults | { success: boolean })?
      local results

      if DEBUG_AUTO_WIN then
        results = { success = true }
      else
        results = Async.await(player:initiate_encounter(encounter_path, data))
      end

      if not results or not results.success then
        if enemy then
          EnemyHelpers.sync_health(enemy, results)
        end

        player:complete_turn()
        return
      end

      if panel.type == PanelTypes.DARK_HOLE then
        selection:set_shape(DARK_HOLE_SHAPE, 0, -1)
      end

      local panels = selection:get_panels()

      Async.await(player:liberate_panels(panels, results))

      -- destroy enemy
      local destroyed_enemy = Async.await(Enemy.destroy(self, enemy or panel.enemy))

      if destroyed_enemy and #self.dark_holes == 0 then
        convert_indestructible_panels(self)
      end

      -- loot
      Async.await(player:loot_panels(panels))

      -- figure out if we've won
      if destroyed_enemy and enemy and enemy.is_boss then
        liberate(self)
      else
        player:complete_turn()
      end
    end
  end)
end

---@param self Liberation.MissionInstance
local function take_enemy_turn(self)
  self.updating = true

  return Async.create_scope(function()
    local hold_time = .15
    local slide_time = .5
    local down_count = 0

    for _, player in ipairs(self.players) do
      if player.health == 0 then
        down_count = down_count + 1
      end
    end

    if down_count == #self.players then
      for _, player in ipairs(self.players) do
        player:message_with_mug("We're all down?\nRetreat!\nRetreat!!").and_then(function()
          local boss_point_found = false
          local point = nil

          for p = 1, #self.points_of_interest, 1 do
            point = self.points_of_interest[p]
            boss_point_found = point.custom_properties["isBoss"] == "true"
            if boss_point_found then break end
          end

          -- todo: pan to boss and display taunt text?
          if boss_point_found then
            Net.slide_player_camera(player.id, point.x + .5, point.y + .5, point.z, slide_time)
            Async.sleep(slide_time).and_then(function()
              player:message_with_mug("Is this the power of " ..
                self:get_panel_at(point.x, point.y, point.z).custom_properties["Boss"] .. "...?").and_then(function()
                boot_player(player, false, self.area_name)
                Net.unlock_player_camera(player.id)
                Net.unlock_player_input(player.id)
              end)
            end)
          end
        end)
      end

      self.updating = false

      if self.needs_disposal then
        self:destroy()
      end

      return
    end

    for _, enemy in ipairs(self.enemies) do
      for _, player in ipairs(self.players) do
        Net.slide_player_camera(player.id, enemy.x + .5, enemy.y + .5, enemy.z, slide_time)
      end

      -- wait until the camera is done moving
      Async.await(Async.sleep(slide_time))

      if enemy.is_boss then
        -- darkloids heal up to 50% of health during their turn
        Async.await(EnemyHelpers.heal(enemy, enemy.max_health / 2))
      end

      Async.await(enemy:take_turn())

      -- wait a short amount of time to look nicer if there was no action taken
      Async.await(Async.sleep(hold_time))
    end

    -- dark holes!
    for _, dark_hole in ipairs(self.dark_holes) do
      -- see if we need to spawn a new enemy
      if Enemy.is_alive(dark_hole.enemy) then
        goto continue
      end

      -- find an available space
      -- todo: move out of func
      local neighbor_offsets = {
        { 1,  -1 },
        { 1,  0 },
        { 1,  1 },
        { -1, -1 },
        { -1, 0 },
        { -1, 1 },
        { 0,  1 },
        { 0,  -1 },
      }

      local neighbors = {}

      for _, neighbor_offset in ipairs(neighbor_offsets) do
        local x = dark_hole.x + neighbor_offset[1]
        local y = dark_hole.y + neighbor_offset[2]
        local z = dark_hole.z

        local panel = self:get_panel_at(x, y, z)

        if panel and PanelTypes.ENEMY_WALKABLE[panel.type] and not self:get_enemy_at(x, y, z) then
          neighbors[#neighbors + 1] = panel
        end
      end

      if #neighbors == 0 then
        -- no available spaces
        goto continue
      end

      -- pick a neighbor to be the destination
      local destination = neighbors[math.random(#neighbors)]

      -- move the camera here
      for _, player in ipairs(self.players) do
        Net.slide_player_camera(player.id, dark_hole.x + .5, dark_hole.y + .5, dark_hole.z, slide_time)
      end

      -- wait until the camera is done moving
      Async.await(Async.sleep(slide_time))

      -- spawn a new enemy
      local name = dark_hole.custom_properties.Spawns
      local direction = dark_hole.custom_properties.Direction
      local rank = dark_hole.custom_properties.Rank

      dark_hole.enemy = Enemy.from(self, dark_hole, direction, name, rank)
      self.enemies[#self.enemies + 1] = dark_hole.enemy

      -- Let people admire the enemy
      local admire_time = .5
      Async.await(Async.sleep(admire_time))

      -- move them out
      Async.await(EnemyHelpers.move(self, dark_hole.enemy, destination.x, destination.y, destination.z))

      -- Needs more admiration
      Async.await(Async.sleep(admire_time))

      ::continue::
    end

    -- completed turn, return camera to players
    for _, player in ipairs(self.players) do
      local x, y, z = player:position_multi()

      -- Slide camera back to the player
      Net.slide_player_camera(player.id, x, y, z, slide_time)

      -- Return camera control
      Net.unlock_player_camera(player.id)

      -- If they aren't paralyzed or otherwise unable to move, return input
      if player.is_trapped ~= true then Net.unlock_player_input(player.id) end
    end

    -- wait for the camera
    Async.await(Async.sleep(slide_time))

    -- give turn back to players
    for _, player in ipairs(self.players) do
      player:give_turn()
    end

    self.emote_timer = 0
    self.phase = self.phase + 1
    self.updating = false

    if self.needs_disposal then
      self:destroy()
    end
  end)
end

---@class Liberation._PanelObject: Net.Object
---@field visual_object_id number
---@field enemy Liberation.Enemy
---@field loot Liberation._Loot?

-- public
---@class Liberation.MissionInstance
---@field area_id string
---@field area_name string
---@field default_encounter string
---@field package emote_timer number
---@field package target_phase Liberation._TargetPhase
---@field package liberated boolean
---@field phase number
---@field ready_count number
---@field order_points number
---@field MAX_ORDER_POINTS number
---@field points_of_interest Net.Object[]
---@field players Liberation.Player[]
---@field player_map table<Net.ActorId, Liberation.Player>
---@field package boss Liberation.Enemy
---@field enemies Liberation.Enemy[]
---@field panels table<number, table<number, table<number, Liberation._PanelObject>>>
---@field dark_holes Liberation._PanelObject[]
---@field indestructible_panels Liberation._PanelObject[]
---@field gate_panels Liberation._PanelObject[]
---@field panel_gid_map table<string, number>
---@field package spawn_positions Net.Object[]
---@field package net_listeners [string, fun()][]
---@field package updating boolean
---@field package needs_disposal boolean
---@field package disposal_promise Net.Promise?
local MissionInstance = {}

---@return Liberation.MissionInstance
function MissionInstance:new(base_area_id, new_area_id)
  local mission = {
    area_id = new_area_id,
    area_name = Net.get_area_name(base_area_id),
    default_encounter = Net.get_area_custom_property(base_area_id, "Liberation Encounter"),
    emote_timer = 0,
    target_phase = TargetPhase:new(base_area_id),
    liberated = false,
    phase = 1,
    ready_count = 0,
    order_points = 3,
    MAX_ORDER_POINTS = 8,
    points_of_interest = {},
    players = {},
    player_map = {},
    boss = nil,
    enemies = {},
    panels = {},
    dark_holes = {},
    indestructible_panels = {},
    gate_panels = {},
    panel_gid_map = {},
    spawn_positions = {},
    net_listeners = {},
    updating = false,
    needs_disposal = false,
    disposal_promise = nil
  }

  for i = 1, Net.get_layer_count(base_area_id), 1 do
    -- create a layer of panels
    local panel_layer = {}

    for j = 1, Net.get_layer_height(base_area_id), 1 do
      --Now we need to create the actual row of panels we'll be using within that layer.
      panel_layer[j] = {}
    end

    mission.panels[i] = panel_layer
  end

  setmetatable(mission, self)
  self.__index = self

  Net.clone_area(base_area_id, new_area_id)

  --Code for handling addition of compression rodes to Liberation Missions.
  --Basically searches and adds compression objects in the instance to the list.
  --They get cleaned up later.

  --Add the instance to the list of collider areas.
  compression.colliders[new_area_id] = {}
  for _, object_id in ipairs(Net.list_objects(new_area_id)) do
    local object = Net.get_object_by_id(new_area_id, object_id)
    --Find a way to detect if object is already added somehow. Shouldn't be an issue since instances, but...
    --Could be cleaner.
    if object.custom_properties.Compress or object.custom_properties.Decompress then
      table.insert(compression.colliders[new_area_id], object)
    end
  end

  Preloader.update(new_area_id)

  -- resolve panels and enemies
  local object_ids = Net.list_objects(mission.area_id)
  local type_gid_seen_map = {}

  for _, object_id in ipairs(object_ids) do
    local object = Net.get_object_by_id(mission.area_id, object_id)

    if object.name == "Point of Interest" then
      -- track points of interest for the camera
      mission.points_of_interest[#mission.points_of_interest + 1] = object
      -- delete to reduce map size
      Net.remove_object(mission.area_id, object_id)
    elseif PanelTypes.ALL[object.type] then
      -- track gid
      local type_map = mission.panel_gid_map[object.type]

      if not type_map then
        type_map = {}
        mission.panel_gid_map[object.type] = type_map
        type_gid_seen_map[object.type] = {}
      end

      local gid_seen_map = type_gid_seen_map[object.type]

      if not gid_seen_map[object.data.gid] then
        gid_seen_map[object.data.gid] = true
        type_map[#type_map + 1] = object.data.gid
      end

      -- create panel
      local panel = mission:create_panel(object)

      -- spawning bosses
      if object.custom_properties.Boss then
        local name = object.custom_properties.Boss
        local direction = object.custom_properties.Direction
        local rank = object.custom_properties.Rank
        local enemy = Enemy.from(mission, object, direction, name, rank)
        enemy.is_boss = true

        self.boss = enemy
        table.insert(mission.enemies, 1, enemy) -- make the boss the first enemy in the list
      end

      -- spawning enemies
      if object.custom_properties.Spawns then
        local name = object.custom_properties.Spawns
        local direction = object.custom_properties.Direction
        local rank = object.custom_properties.Rank
        local position = {
          x = object.x,
          y = object.y,
          z = object.z
        }

        position = EnemyHelpers.offset_position_with_direction(position, direction)

        local enemy = Enemy.from(mission, position, direction, name, rank)
        panel.enemy = enemy

        table.insert(mission.enemies, enemy)
      end
    end
  end

  -- resolve spawn positions
  local current_spawn = Net.get_object_by_name(new_area_id, "Spawn")
  mission.spawn_positions = { current_spawn }
  local spawns_loaded = {}

  while true do
    local id = current_spawn.custom_properties["Next Spawn"]

    if not id or spawns_loaded[id] then
      -- prevent infinite loops
      break
    end

    spawns_loaded[id] = true

    current_spawn = Net.get_object_by_id(mission.area_id, id)

    if not current_spawn then
      break
    end

    mission.spawn_positions[#mission.spawn_positions + 1] = current_spawn
  end

  -- add event listeners
  local function add_event_listener(name, callback)
    mission.net_listeners[#mission.net_listeners + 1] = { name, callback }
    Net:on(name, callback)
  end

  add_event_listener("tick", function(event)
    mission:tick(event.delta_time)
  end)

  add_event_listener("handle_tile_interaction", function(event)
    mission:handle_tile_interaction(event.player_id, event.x, event.y, event.z, event.button)
  end)

  add_event_listener("object_interaction", function(event)
    mission:handle_object_interaction(event.player_id, event.object_id)
  end)

  add_event_listener("player_area_transfer", function(event)
    if Net.get_player_area(event.player_id) ~= new_area_id then
      mission:handle_player_disconnect(event.player_id)
    end
  end)

  add_event_listener("player_disconnect", function(event)
    mission:handle_player_disconnect(event.player_id)
  end)

  return mission
end

function MissionInstance:transfer_player(player_id)
  local spawn_position = self.spawn_positions[#self.players % #self.spawn_positions + 1]

  local player = Player:new(self, player_id)
  self.players[#self.players + 1] = player
  self.player_map[player_id] = player
  self.target_phase.players_joined = self.target_phase.players_joined + 1

  Net.transfer_player(player.id, self.area_id, true, spawn_position.x, spawn_position.y, spawn_position.z)
end

function MissionInstance:destroy()
  if not self.disposal_promise then
    self.disposal_promise = Async.create_promise(function(resolve)
      self.resolve_disposal = resolve
    end)
  end

  if self.updating then
    -- mark as needs_disposal to clean up after async functions complete
    self.needs_disposal = true
    return self.disposal_promise
  end

  for _, id in ipairs(Net.list_bots(self.area_id)) do
    Net.remove_bot(id)
  end

  Net.remove_area(self.area_id)
  self.resolve_disposal(nil)

  for i = #self.net_listeners, 1, -1 do
    local name, callback = table.unpack(self.net_listeners[i])
    self.net_listeners[i] = nil

    Net:remove_listener(name, callback)
  end

  return self.disposal_promise
end

function MissionInstance:destroying()
  return self.needs_disposal
end

---@package
function MissionInstance:tick(elapsed)
  if not self.liberated and self.ready_count == #self.players then
    self.ready_count = 0
    -- now we can take a turn !
    take_enemy_turn(self)
  end

  self.emote_timer = self.emote_timer - elapsed

  if self.emote_timer <= 0 then
    for _, player in ipairs(self.players) do
      player:emote_state()
    end

    -- emote every second
    self.emote_timer = 1
  end
end

---@package
function MissionInstance:handle_tile_interaction(player_id, x, y, z, button)
  local player = self.player_map[player_id]

  if not player then return end

  local player_x, player_y, player_z = player:position_multi()
  local panel_under_player = self:get_panel_at(player_x, player_y, player_z)

  if panel_under_player then return end

  if button == 1 then
    -- Shoulder L
    return
  end

  if player.completed_turn or Net.is_player_in_widget(player_id) then
    -- ignore selection as it's not our turn or waiting for a response
    return
  end

  Net.lock_player_input(player_id)

  local quiz_promise = player:quiz_with_points("Pass", "Cancel")

  quiz_promise.and_then(function(response)
    if response == 0 then
      -- Pass
      player:get_pass_turn_permission()
    elseif response == 1 then
      -- Cancel
      Net.unlock_player_input(player_id)
    end
  end)
end

---@package
function MissionInstance:handle_object_interaction(player_id, object_id, button)
  local player = self.player_map[player_id]

  if not player then return end

  local player_position = player:position()
  local panel_under_player = self:get_panel_at(player_position.x, player_position.y, player_position.z)

  -- Player is moving over dark panels with an ability and thus cannot interact.
  if panel_under_player then return end

  if button == 1 then
    -- Shoulder L
    return
  end

  if player.completed_turn or Net.is_player_in_widget(player_id) then
    -- ignore selection as it's not our turn or waiting for a response
    return
  end

  -- panel selection detection

  local object = Net.get_object_by_id(self.area_id, object_id)

  if not object then
    -- must have been liberated
    local x, y, z = player_position.x, player_position.y, player_position.z
    self:handle_tile_interaction(player_id, x, y, z, button)
    return
  end

  if not is_adjacent(player_position, object) then
    -- can't select panels diagonally
    return
  end

  local panel = self:get_panel_at(object.x, object.y, object.z)

  if not panel then
    -- no data associated with this object
    return
  end

  Net.lock_player_input(player_id)

  local panel_already_selected = false

  for _, player in ipairs(self.players) do
    if player.selection.root_panel == panel then
      panel_already_selected = true
      break
    end
  end

  local can_liberate = not panel_already_selected and PanelTypes.LIBERATABLE[panel.type]

  if not can_liberate then
    -- indestructible panels
    local quiz_promise = player:quiz_with_points("Pass", "Cancel")

    quiz_promise.and_then(function(response)
      if response == 0 then
        -- Pass
        player:get_pass_turn_permission()
      elseif response == 1 then
        -- Cancel
        Net.unlock_player_input(player_id)
      end
    end)

    return
  end

  local ability = player.ability
  local can_use_ability = (
    ability ~= nil and
    ability.question and                                 -- no question = passive ability
    not self:get_enemy_at(panel.x, panel.y, panel.z) and -- cant have an enemy standing on this tile
    self.order_points >= ability.cost and
    PanelTypes.ABILITY_ACTIONABLE[panel.type]
  )

  player.selection:select_panel(panel)

  if ability and can_use_ability then
    local quiz_promise = player:quiz_with_points(
      "Liberation",
      ability.name,
      "Pass"
    )

    quiz_promise.and_then(function(response)
      if response == 0 then
        -- Liberate
        liberate_panel(self, player)
      elseif response == 1 then
        -- Ability
        local selection_shape, shape_offset_x, shape_offset_y = ability.generate_shape(self, player)
        player.selection:set_shape(selection_shape, shape_offset_x, shape_offset_y)

        -- ask if we should use the ability
        player:get_ability_permission()
      elseif response == 2 then
        -- Pass
        player.selection:clear()
        player:get_pass_turn_permission()
      end
    end)
    return
  end

  local quiz_promise = player:quiz_with_points(
    "Liberation",
    "Pass",
    "Cancel"
  )

  quiz_promise.and_then(function(response)
    if response == 0 then
      -- Liberation
      liberate_panel(self, player)
    elseif response == 1 then
      -- Pass
      player.selection:clear()
      player:get_pass_turn_permission()
    elseif response == 2 then
      -- Cancel
      player.selection:clear()
      Net.unlock_player_input(player_id)
    end
  end)
end

---@package
function MissionInstance:handle_player_disconnect(player_id)
  local player = self.player_map[player_id]

  if not player then return end

  self.player_map[player_id] = nil

  for i, p in ipairs(self.players) do
    if player == p then
      table.remove(self.players, i)
      break
    end
  end

  player:handle_disconnect()
end

function MissionInstance:get_players()
  return self.players
end

-- helper functions
function MissionInstance:get_panel_at(x, y, z)
  y = math.floor(y) + 1
  z = math.floor(z) + 1

  local layer = self.panels[z]

  if not layer then
    return nil
  end

  local row = layer[y]

  if row == nil then
    return nil
  end

  x = math.floor(x) + 1
  return row[x]
end

function MissionInstance:remove_panel(panel)
  local y = math.floor(panel.y) + 1
  local z = math.floor(panel.z) + 1
  local row = self.panels[z][y]

  if row == nil then
    return nil
  end

  local x = math.floor(panel.x) + 1

  if row[x] == nil then
    return
  end

  Net.remove_object(self.area_id, panel.visual_object_id)
  Net.remove_object(self.area_id, panel.id)
  row[x] = nil

  if panel.type == PanelTypes.DARK_HOLE then
    for i, dark_hole in ipairs(self.dark_holes) do
      if panel == dark_hole then
        table.remove(self.dark_holes, i)
        break
      end
    end
  end
end

function MissionInstance:get_enemy_at(x, y, z)
  x = math.floor(x)
  y = math.floor(y)

  for _, enemy in ipairs(self.enemies) do
    if enemy.x == x and enemy.y == y and enemy.z == z then
      return enemy
    end
  end

  return nil
end

---@param object Net.Object
---@return Liberation._PanelObject
function MissionInstance:create_panel(object)
  --Create the actual panel we'll be using with collisions
  local new_panel = {
    name = "",
    type = object.type,
    visible = true,
    x = object.x,
    y = object.y,
    z = object.z,
    width = object.width,
    height = object.height,
    data = { type = "tile", gid = Net.get_tileset(self.area_id, "/server/assets/tiles/Liberation Collision.tsx").first_gid },
    custom_properties = object.custom_properties
  }

  new_panel.id = Net.create_object(self.area_id, new_panel)
  new_panel.visual_object_id = object.id

  -- insert the panel before spawning enemies
  local x = math.floor(object.x) + 1
  local y = math.floor(object.y) + 1
  local z = math.floor(object.z) + 1
  self.panels[z][y][x] = new_panel

  if object.type == PanelTypes.ITEM then
    --if it has a set drop, try to apply it.
    if object.custom_properties["Specific Loot"] ~= nil then
      local check_loot = object.custom_properties["Specific Loot"]

      for i = 1, #Loot.FULL_POOL, 1 do
        local potential_loot = Loot.FULL_POOL[i]

        if potential_loot.animation == check_loot then
          new_panel.loot = potential_loot
          break
        end
      end
    else
      --otherwise, give it random loot from the basic pool.
      new_panel.loot = Loot.DEFAULT_POOL[math.random(#Loot.DEFAULT_POOL)]
    end
  elseif object.type == PanelTypes.DARK_HOLE then
    -- track dark holes for converting indestructible panels
    table.insert(self.dark_holes, new_panel)
  elseif object.type == PanelTypes.INDESTRUCTIBLE then
    -- track indestructible panels for conversion
    table.insert(self.indestructible_panels, new_panel)
  elseif object.type == PanelTypes.GATE then
    table.insert(self.gate_panels, new_panel)
  end

  return new_panel
end

-- exporting
return MissionInstance
