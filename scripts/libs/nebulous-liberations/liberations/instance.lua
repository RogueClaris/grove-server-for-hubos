local PlayerSession = require("scripts/libs/nebulous-liberations/liberations/player_session")
local Enemy = require("scripts/libs/nebulous-liberations/liberations/enemy")
local EnemyHelpers = require("scripts/libs/nebulous-liberations/liberations/enemy_helpers")
local PanelEncounters = require("scripts/libs/nebulous-liberations/liberations/panel_encounters")
local Loot = require("scripts/libs/nebulous-liberations/liberations/loot")
local PanelTypes = require("scripts/libs/nebulous-liberations/liberations/panel_types")
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
      "Target: " .. self.target_phase .. "\n" ..
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
local function convert_indestructible_panels(self)
  local slide_time = .5
  local hold_time = 2

  -- notify players
  for _, player_session in pairs(self.player_sessions) do
    player_session.player:message("No more DarkHoles! Nothing will save the Darkloids now!")

    local player = player_session.player

    Net.lock_player_input(player.id)

    Net.slide_player_camera(player.id, self.boss.x, self.boss.y, self.boss.z, slide_time)

    -- hold the camera
    Net.move_player_camera(player.id, self.boss.x, self.boss.y, self.boss.z, hold_time)

    -- return the camera
    Net.slide_player_camera(player.id, player.x, player.y, player.z, slide_time)
    Net.unlock_player_camera(player.id)
  end

  Async.await(Async.sleep(slide_time + hold_time / 2))

  -- convert panels
  for _, panel in ipairs(self.indestructible_panels) do
    panel.data.gid = self.BASIC_PANEL_GID
    Net.set_object_data(self.area_id, panel.id, panel.data)
  end

  self.indestructible_panels = {}

  Async.await(Async.sleep(hold_time / 2 + slide_time))

  -- returning control
  for _, player_session in pairs(self.player_sessions) do
    if not player_session.completed_turn then
      Net.unlock_player_input(player_session.player.id)
    end
  end
end

---@param self Liberation.Mission
---@param player_session Liberation.PlayerSession
local function liberate_panel(self, player_session)
  return Async.create_scope(function()
    local player = player_session.player
    local selection = player_session.selection
    local panel = selection.root_panel

    if panel.type == PanelTypes.BONUS then
      if panel.custom_properties["Message"] ~= nil then
        Async.await(player:message_with_mug(panel.custom_properties["Message"]))
      else
        Async.await(player:message_with_mug("A BonusPanel! What's it hiding?"))
      end

      self:remove_panel(panel)

      selection:clear()

      Async.await(Loot.loot_bonus_panel(self, player_session, panel))

      Net.unlock_player_input(player_session.player.id)
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
        EnemyHelpers.face_position(enemy, player.x, player.y)
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
        results = Async.await(player_session:initiate_encounter(encounter_path, data))
      end

      if not results or not results.success then
        if enemy then
          EnemyHelpers.sync_health(enemy, results)
        end

        player_session:complete_turn()
        return
      end

      if panel.type == PanelTypes.DARK_HOLE then
        selection:set_shape(DARK_HOLE_SHAPE, 0, -1)
      end

      local panels = selection:get_panels()

      Async.await(player_session:liberate_panels(panels, results))

      -- destroy enemy
      local destroyed_enemy = Async.await(Enemy.destroy(self, enemy or panel.enemy))

      if destroyed_enemy and #self.dark_holes == 0 then
        convert_indestructible_panels(self)
      end

      -- loot
      Async.await(player_session:loot_panels(panels))

      print(enemy and enemy.is_boss)
      -- figure out if we've won
      if destroyed_enemy and enemy and enemy.is_boss then
        liberate(self)
      else
        player_session:complete_turn()
      end
    end
  end)
end

local function take_enemy_turn(self)
  self.updating = true

  return Async.create_scope(function()
    local hold_time = .15
    local slide_time = .5
    local down_count = 0

    for _, player_session in pairs(self.player_sessions) do
      if player_session.health == 0 then
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
        self:clean_up()
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
      local rank = tonumber(dark_hole.custom_properties.Rank) or 1

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
    for _, player in pairs(self.players) do
      -- Slide camera back to the player
      Net.slide_player_camera(player.id, player.x, player.y, player.z, slide_time)

      -- Return camera control
      Net.unlock_player_camera(player.id)

      -- If they aren't paralyzed or otherwise unable to move, return input
      local session = self.player_sessions[player.id]
      if session.is_trapped ~= true then Net.unlock_player_input(player.id) end
    end

    -- wait for the camera
    Async.await(Async.sleep(slide_time))

    -- give turn back to players
    for _, player_session in pairs(self.player_sessions) do
      player_session:give_turn()
    end

    self.emote_timer = 0
    self.phase = self.phase + 1
    self.updating = false

    if self.needs_disposal then
      self:clean_up()
    end
  end)
end

---@class Liberation._PanelObject: Net.Object
---@field visual_object_id number
---@field enemy Liberation.Enemy
---@field loot Liberation._Loot?

-- public
---@class Liberation.Mission
---@field area_id string
---@field area_name string
---@field default_encounter string
---@field package emote_timer number
---@field package target_phase number
---@field package liberated boolean
---@field package phase number
---@field ready_count number
---@field package order_points number
---@field package MAX_ORDER_POINTS number
---@field points_of_interest Net.Object[]
---@field package players LiberationPlayer[]
---@field package player_sessions Liberation.PlayerSession[]
---@field package boss Liberation.Enemy
---@field package enemies Liberation.Enemy[]
---@field package panels table<number, table<number, table<number, Liberation._PanelObject>>>
---@field package dark_holes Net.Object[]
---@field package indestructible_panels Net.Object[]
---@field gate_panels Net.Object[]
---@field package updating boolean
---@field package needs_disposal boolean
---@field package disposal_promise Net.Promise?
local Mission = {}

function Mission:new(base_area_id, new_area_id, players)
  local base_target_phase = tonumber(Net.get_area_custom_property(base_area_id, "Target Phase")) or 10
  local base_player_count = tonumber(Net.get_area_custom_property(base_area_id, "Target Player Count")) or 1
  local minimum_phase_target = tonumber(Net.get_area_custom_property(base_area_id, "Minimum Target Phase")) or 1
  local solo_target_phase = base_target_phase * base_player_count

  local mission = {
    area_id = new_area_id,
    area_name = Net.get_area_name(base_area_id),
    default_encounter = Net.get_area_custom_property(base_area_id, "Liberation Encounter"),
    emote_timer = 0,
    target_phase = math.max(minimum_phase_target, math.ceil(solo_target_phase / #players)),
    liberated = false,
    phase = 1,
    ready_count = 0,
    order_points = 3,
    MAX_ORDER_POINTS = 8,
    points_of_interest = {},
    players = players,
    player_sessions = {},
    boss = nil,
    enemies = {},
    panels = {},
    dark_holes = {},
    indestructible_panels = {},
    gate_panels = {},
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

  ---@param object Net.Object
  ---@return Liberation._PanelObject
  local function create_panel(object)
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
      data = { type = "tile", gid = Net.get_tileset(base_area_id, "/server/assets/tiles/Liberation Collision.tsx").first_gid },
      custom_properties = object.custom_properties
    }

    new_panel.id = Net.create_object(new_area_id, new_panel)
    new_panel.visual_object_id = object.id

    -- insert the panel before spawning enemies
    local x = math.floor(object.x) + 1
    local y = math.floor(object.y) + 1
    local z = math.floor(object.z) + 1
    mission.panels[z][y][x] = new_panel

    -- spawning bosses
    if object.custom_properties.Boss then
      local name = object.custom_properties.Boss
      local direction = object.custom_properties.Direction
      local rank = tonumber(object.custom_properties.Rank) or 1
      local enemy = Enemy.from(mission, object, direction, name, rank)
      enemy.is_boss = true

      mission.boss = enemy
      table.insert(mission.enemies, 1, enemy) -- make the boss the first enemy in the list
    end

    -- spawning enemies
    if object.custom_properties.Spawns then
      local name = object.custom_properties.Spawns
      local direction = object.custom_properties.Direction
      local rank = tonumber(object.custom_properties.Rank) or 1
      local position = {
        x = object.x,
        y = object.y,
        z = object.z
      }

      position = EnemyHelpers.offset_position_with_direction(position, direction)

      local enemy = Enemy.from(mission, position, direction, name, rank)
      new_panel.enemy = enemy

      table.insert(mission.enemies, enemy)
    end

    return new_panel
  end

  for _, object_id in ipairs(object_ids) do
    local object = Net.get_object_by_id(mission.area_id, object_id)

    if object.name == "Point of Interest" then
      -- track points of interest for the camera
      mission.points_of_interest[#mission.points_of_interest + 1] = object
      -- delete to reduce map size
      Net.remove_object(mission.area_id, object_id)
    elseif PanelTypes.ALL[object.type] then
      local panel = create_panel(object)

      if object.type == PanelTypes.ITEM then
        --if it has a set drop, try to apply it.
        if object.custom_properties["Specific Loot"] ~= nil then
          local check_loot = object.custom_properties["Specific Loot"]

          for i = 1, #Loot.FULL_POOL, 1 do
            local potential_loot = Loot.FULL_POOL[i]

            if potential_loot.animation == check_loot then
              panel.loot = potential_loot
              break
            end
          end
        else
          --otherwise, give it random loot from the basic pool.
          panel.loot = Loot.DEFAULT_POOL[math.random(#Loot.DEFAULT_POOL)]
        end
      elseif object.type == PanelTypes.DARK_HOLE then
        -- track dark holes for converting indestructible panels
        table.insert(mission.dark_holes, panel)
      elseif object.type == PanelTypes.INDESTRUCTIBLE then
        -- track indestructible panels for conversion
        table.insert(mission.indestructible_panels, panel)
      elseif object.type == PanelTypes.GATE then
        table.insert(mission.gate_panels, panel)
      end
    end
  end

  return mission
end

function Mission:clean_up()
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

  return self.disposal_promise
end

function Mission:cleaning_up()
  return self.needs_disposal
end

function Mission:begin()
  for _, player in ipairs(self.players) do
    -- create data
    self.player_sessions[player.id] = PlayerSession:new(self, player)
  end
end

function Mission:tick(elapsed)
  if not self.liberated and self.ready_count == #self.players then
    self.ready_count = 0
    -- now we can take a turn !
    take_enemy_turn(self)
  end

  self.emote_timer = self.emote_timer - elapsed

  if self.emote_timer <= 0 then
    for _, player_session in pairs(self.player_sessions) do
      player_session:emote_state()
    end

    -- emote every second
    self.emote_timer = 1
  end
end

function Mission:handle_tile_interaction(player_id, x, y, z, button)
  local player_session = self.player_sessions[player_id]

  local panel_under_player = self:get_panel_at(player_session.player.x, player_session.player.y, player_session.player.z)

  if panel_under_player then return end

  if button == 1 then
    -- Shoulder L
    return
  end

  if player_session.completed_turn or Net.is_player_in_widget(player_id) then
    -- ignore selection as it's not our turn or waiting for a response
    return
  end

  Net.lock_player_input(player_id)

  local quiz_promise = player_session:quiz_with_points("Pass", "Cancel")

  quiz_promise.and_then(function(response)
    if response == 0 then
      -- Pass
      player_session:get_pass_turn_permission()
    elseif response == 1 then
      -- Cancel
      Net.unlock_player_input(player_id)
    end
  end)
end

function Mission:handle_object_interaction(player_id, object_id, button)
  local player_session = self.player_sessions[player_id]

  if not player_session then return end

  local panel_under_player = self:get_panel_at(player_session.player.x, player_session.player.y, player_session.player.z)

  -- Player is moving over dark panels with an ability and thus cannot interact.
  if panel_under_player then return end

  if button == 1 then
    -- Shoulder L
    return
  end

  if player_session.completed_turn or Net.is_player_in_widget(player_id) then
    -- ignore selection as it's not our turn or waiting for a response
    return
  end

  -- panel selection detection

  local object = Net.get_object_by_id(self.area_id, object_id)

  if not object then
    -- must have been liberated
    local x, y, z = player_session.player.x, player_session.player.y, player_session.player.z
    self:handle_tile_interaction(player_id, x, y, z, button)
    return
  end

  if not is_adjacent(player_session.player, object) then
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

  for _, player_session in pairs(self.player_sessions) do
    if player_session.selection.root_panel == panel then
      panel_already_selected = true
      break
    end
  end

  local can_liberate = not panel_already_selected and PanelTypes.LIBERATABLE[panel.type]

  if not can_liberate then
    -- indestructible panels
    local quiz_promise = player_session:quiz_with_points("Pass", "Cancel")

    quiz_promise.and_then(function(response)
      if response == 0 then
        -- Pass
        player_session:get_pass_turn_permission()
      elseif response == 1 then
        -- Cancel
        Net.unlock_player_input(player_id)
      end
    end)

    return
  end

  local ability = player_session.ability
  local can_use_ability = (
    ability ~= nil and
    ability.question and                                 -- no question = passive ability
    not self:get_enemy_at(panel.x, panel.y, panel.z) and -- cant have an enemy standing on this tile
    self.order_points >= ability.cost and
    PanelTypes.ABILITY_ACTIONABLE[panel.type]
  )

  player_session.selection:select_panel(panel)

  if ability and can_use_ability then
    local quiz_promise = player_session:quiz_with_points(
      "Liberation",
      ability.name,
      "Pass"
    )

    quiz_promise.and_then(function(response)
      if response == 0 then
        -- Liberate
        liberate_panel(self, player_session)
      elseif response == 1 then
        -- Ability
        local selection_shape, shape_offset_x, shape_offset_y = ability.generate_shape(self, player_session)
        player_session.selection:set_shape(selection_shape, shape_offset_x, shape_offset_y)

        -- ask if we should use the ability
        player_session:get_ability_permission()
      elseif response == 2 then
        -- Pass
        player_session.selection:clear()
        player_session:get_pass_turn_permission()
      end
    end)
    return
  end

  local quiz_promise = player_session:quiz_with_points(
    "Liberation",
    "Pass",
    "Cancel"
  )

  quiz_promise.and_then(function(response)
    if response == 0 then
      -- Liberation
      liberate_panel(self, player_session)
    elseif response == 1 then
      -- Pass
      player_session.selection:clear()
      player_session:get_pass_turn_permission()
    elseif response == 2 then
      -- Cancel
      player_session.selection:clear()
      Net.unlock_player_input(player_id)
    end
  end)
end

function Mission:handle_player_avatar_change(player_id)
  local player = self.player_sessions[player_id].player
  player:boot_to_lobby(false, self.area_name)
end

function Mission:handle_player_disconnect(player_id)
  for i, player in ipairs(self.players) do
    if player_id == player.id then
      table.remove(self.players, i)
      break
    end
  end

  self.player_sessions[player_id]:handle_disconnect()
  self.player_sessions[player_id] = nil
end

function Mission:get_players()
  return self.players
end

function Mission:get_spawn_position()
  return Net.get_object_by_name(self.area_id, "Spawn")
end

function Mission:get_next_spawn_from_object(object_id)
  local object = Net.get_object_by_id(self.area_id, object_id)
  if object.custom_properties["Next Spawn"] and Net.get_object_by_id(self.area_id, object.custom_properties["Next Spawn"]).type == "Spawn Point" then
    return Net.get_object_by_id(self.area_id, object.custom_properties["Next Spawn"])
  end
  return self:get_spawn_position()
end

-- helper functions
function Mission:get_panel_at(x, y, z)
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

function Mission:remove_panel(panel)
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

function Mission:get_enemy_at(x, y, z)
  x = math.floor(x)
  y = math.floor(y)

  for _, enemy in ipairs(self.enemies) do
    if enemy.x == x and enemy.y == y and enemy.z == z then
      return enemy
    end
  end

  return nil
end

-- exporting
return Mission
