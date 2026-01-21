local player_data = require('scripts/custom-scripts/player_data')

local PlayerSession = require("scripts/libs/nebulous-liberations/liberations/player_session")
local Enemy = require("scripts/libs/nebulous-liberations/liberations/enemy")
local EnemyHelpers = require("scripts/libs/nebulous-liberations/liberations/enemy_helpers")
local PanelEncounters = require("scripts/libs/nebulous-liberations/liberations/panel_encounters")
local Loot = require("scripts/libs/nebulous-liberations/liberations/loot")
local Preloader = require("scripts/libs/nebulous-liberations/liberations/preloader")
local Emotes = require("scripts/libs/emotes")

local compression = require('scripts/custom-scripts/compression')

local function includes(table, value)
  for _, v in ipairs(table) do
    if value == v then
      return true
    end
  end
  return false
end

local panel_type_table = { "Dark Panel", "Dark Hole", "Indestructible Panel", "Item Panel", "Panel Gate", "Bonus Panel",
  "Trap Panel" }
local shadowstep_table = { "Dark Panel", "Item Panel", "Trap Panel" }

local debug = false

-- private functions

local function is_panel(self, object)
  return includes(panel_type_table, object.type)
end

local function is_adjacent(position_a, position_b)
  if position_a.z ~= position_b.z then
    print("[NebuLibs] Object Interaction: Layer mismatch!")
    return false
  end

  local x_diff = math.abs(math.floor(position_a.x) - math.floor(position_b.x))
  local y_diff = math.abs(math.floor(position_a.y) - math.floor(position_b.y))

  return (x_diff + y_diff) == 1
end

local function boot_player(player, isVictory, mapName)
  Net.set_player_emote(player.id, Emotes.BLANK)
  Net.unlock_player_input(player.id)
  -- liberation_flags.set_flags(mapName, player.id)
  compression.decompress(player.id)
  player:boot_to_lobby(isVictory, mapName)
end

local function liberate(self)
  self.is_liberated = true
  compression.colliders[self.area_id] = nil
  for _, layer in pairs(self.panels) do
    for _, row in pairs(layer) do
      for _, panel in pairs(row) do
        if panel then
          self:remove_panel(panel)
        end
      end
    end
  end

  self.panels = {}

  for _, enemy in ipairs(self.enemies) do
    Net.remove_bot(enemy.id, false)
  end

  self.enemies = {}

  Net.set_background(
    self.area_id,
    Net.get_area_custom_properties(self.area_id)["Background Texture"],
    Net.get_area_custom_properties(self.area_id)["Background Animation"],
    Net.get_area_custom_properties(self.area_id)["Background Vel X"],
    Net.get_area_custom_properties(self.area_id)["Background Vel Y"]
  )

  Net.set_song(self.area_id, Net.get_area_custom_properties(self.area_id)["Song"])

  local victory_message =
      self.area_name .. " Liberated\n" ..
      "Target: " .. self.target_phase .. "\n" ..
      "Actual: " .. self.phase

  for _, player in ipairs(self.players) do
    player:message(victory_message).and_then(function()
      boot_player(player, true, self.area_name)
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
    if Net.get_area_custom_properties(self.area_id)["Victory Lap Song"] ~= nil then
      Net.set_song(self.area_id, Net.get_area_custom_properties(self.area_id)["Victory Lap Song"])
    end
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
    local actual_panel = Net.get_object_by_id(self.area_id, panel.visual_object_id)
    actual_panel.data.gid = self.BASIC_PANEL_GID_LIST[#self.BASIC_PANEL_GID_LIST]
    actual_panel.type = "Dark Panel"
    panel.type = "Dark Panel"
    panel.visual_gid = self.BASIC_PANEL_GID_LIST[#self.BASIC_PANEL_GID_LIST]
    Net.set_object_data(self.area_id, actual_panel.id, actual_panel.data)
    Net.set_object_data(self.area_id, panel.id, panel.data)
  end

  self.indestructible_panels = nil

  Async.await(Async.sleep(hold_time / 2 + slide_time))

  -- returning control
  for _, player_session in pairs(self.player_sessions) do
    if not player_session.completed_turn then
      Net.unlock_player_input(player_session.player.id)
    end
  end
end

local function liberate_panel(self, player_session)
  return Async.create_scope(function()
    local player = player_session.player
    local selection = player_session.selection
    local panel = selection.root_panel
    local enemy, data, targeted_panels, encounter_path;

    local end_result = false;

    if panel.type == "Bonus Panel" then
      if panel.custom_properties["Message"] ~= nil then
        Async.await(player:message_with_mug(panel.custom_properties["Message"]))
      else
        Async.await(player:message_with_mug("A BonusPanel! What's it hiding?"))
      end

      self:remove_panel(panel)

      selection:clear()

      Async.await(Loot.loot_bonus_panel(self, player_session, panel))

      end_result = true;
    else
      -- Play appropriate message if set; if not, run Dark Hole message for lode-bearing panels, and run a default message otherwise.
      if panel.custom_properties["Message"] ~= nil then
        Async.await(player:message_with_mug(panel.custom_properties["Message"]))
      elseif panel.type == "Dark Hole" then
        Async.await(player:message_with_mug("A Dark Hole! Begin liberation!"))
      else
        Async.await(player:message_with_mug("Let's do it! Liberate panels!"))
      end

      data = {
        terrain = PanelEncounters.resolve_terrain(self, player),
      }

      -- Obtain enemy
      if panel.enemy then
        enemy = panel.enemy
      else
        enemy = self:get_enemy_at(panel.x, panel.y, panel.z)
      end

      -- If an overworld enemy exists, set facing & data
      -- Otherwise check for a preset encounter on that panel
      -- Default to a random encounter from the area encounter pool
      if enemy then
        EnemyHelpers.face_position(enemy, player.x, player.y)
        encounter_path = enemy.encounter
        data.health = enemy.health
        data.rank = enemy.rank

        -- Boss check for banter
        if panel.custom_properties["Boss"] ~= nil and not enemy.is_engaged then
          Async.await(enemy:do_first_encounter_banter(player.id))
          -- .and_then(function()
          -- if enemy.is_engaged then
          -- Async.create_function(function()
          --   resolve()
          -- end)
          -- end
          -- end)
        end
      elseif panel.custom_properties["Encounter Path"] then
        encounter_path = panel.custom_properties["Encounter Path"]
      else
        encounter_path = PanelEncounters[self.area_name]
      end

      -- Await results before continuing.

      local results = Async.await(Async.initiate_encounter(player.id, encounter_path, data))

      if results == nil then return end

      local total_enemy_health = 0

      for _, target in ipairs(results.enemies) do
        total_enemy_health = total_enemy_health + target.health
      end

      player_session.health = results.health

      Net.set_player_health(player.id, player_session.health)

      Net.set_player_emotion(player.id, results.emotion)

      if player_session.health == 0 then
        player_session:paralyze()
      end

      local success = true

      if total_enemy_health > 0 or results.ran then
        success = false
      end

      if success == false then
        -- Sync enemy health if an overworld enemy exists.
        if enemy then EnemyHelpers.sync_health(enemy, results) end
      else
        -- Assign relevant shape
        if panel.custom_properties["Clear Shape"] ~= nil then
          -- Experimental. Attempt to allow per-panel custom clear shapes.
          selection:set_shape(panel.custom_properties["Clear Shape"], 0, -1)
        elseif panel.type == "Dark Hole" then
          selection:set_shape(DARK_HOLE_SHAPE, 0, -1)
        elseif results.turns == 1 and not results.ran then
          selection:set_shape(DARK_HOLE_SHAPE, 0, -2)
        end

        -- Get panels
        targeted_panels = selection:get_panels()

        -- Await liberation, loot, and completion of player turn
        Async.await(player_session:liberate_and_loot_panels(targeted_panels, results, false, false)).
            and_then(function()
              -- If an overworld enemy exists, destroy it
              if enemy then
                local is_destroyed = Async.await(Enemy.destroy(self, enemy))
                if is_destroyed and enemy.is_boss then
                  liberate(self)
                end
              end
              -- convert the boss' guard panels if no dark holes remain
              if #self.dark_holes == 0 then
                convert_indestructible_panels(self)
              end
            end)
      end
    end
  end)
end

local function take_enemy_turn(self)
  return Async.create_scope(function()
    local hold_time = .15
    local slide_time = .5
    local down_count = 0
    local session;

    for _, player_session in pairs(self.player_sessions) do
      if player_session.health == 0 then
        down_count = down_count + 1
      end
    end

    if down_count == #self.players then
      for _, player in ipairs(self.players) do
        player:message_with_mug("We're all down?\nRetreat!\nRetreat!!").and_then(function()
          local bossPointFound = false
          local point = nil
          for p = 1, #self.points_of_interest, 1 do
            point = self.points_of_interest[p]
            bossPointFound = point.custom_properties["isBoss"] == "true"
            if bossPointFound then break end
          end
          -- todo: pan to boss and display taunt text?
          if bossPointFound then
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

    -- print("[NebuLibs] There are " .. tostring(#self.enemies) .. " enemies")

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
        local panel = self:get_panel_at(dark_hole.x + neighbor_offset[1], dark_hole.y + neighbor_offset[2], dark_hole.z)

        if panel then
          local can_move_to = (
            panel.type == "Dark Panel" or
            panel.type == "Item Panel" or
            panel.type == "Trap Panel"
          )
          if can_move_to then table.insert(neighbors, panel) end
        end
      end

      if #neighbors == 0 then
        -- no available spaces
        goto continue
      end

      -- pick a neighbor to be the destination
      local destination = neighbors[math.random(#neighbors)] --Move here in one go
      -- move the camera here
      for _, player in ipairs(self.players) do
        Net.slide_player_camera(player.id, dark_hole.x + .5, dark_hole.y + .5, dark_hole.z, slide_time)
      end

      -- wait until the camera is done moving
      Async.await(Async.sleep(slide_time))

      -- spawn a new enemy
      local name = dark_hole.custom_properties.Spawns
      local direction = dark_hole.custom_properties.Direction
      local rank = dark_hole.custom_properties.Rank or 1

      dark_hole.enemy = Enemy.from(self, dark_hole, direction, name, rank)
      table.insert(self.enemies, dark_hole.enemy)

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
      session = self.player_sessions[player.id]
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

    self.updating = true
  end)
end

-- public
local Mission = {}

function Mission:new(base_area_id, new_area_id, players)
  local FIRST_PANEL_GID = Net.get_tileset(base_area_id, Net.get_area_custom_property(base_area_id, "Liberation Tileset"))
      .first_gid
  local TOTAL_PANEL_GIDS = 1
  local solo_target = tonumber(Net.get_area_custom_property(base_area_id, "Target Phase Count")) or 13
  local desired_players = tonumber(Net.get_area_custom_property(base_area_id, "Target Player Count")) or 3
  local minimum_phases = tonumber(Net.get_area_custom_property(base_area_id, "Minimum Target Phase Count")) or 1
  local player_difference = #players - desired_players
  local mission = {
    area_id = new_area_id,
    area_name = Net.get_area_name(base_area_id),
    emote_timer = 0,
    target_phase = math.max(minimum_phases, math.ceil(solo_target / math.max(1, player_difference))),
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
    panel_gates = {},
    FIRST_PANEL_GID = FIRST_PANEL_GID,
    BASIC_PANEL_GID_LIST = {},
    ITEM_PANEL_GID_LIST = {},
    DARK_HOLE_GID_LIST = {},
    INDESTRUCTIBLE_PANEL_GID_LIST = {},
    BONUS_PANEL_GID_LIST = {},
    TRAP_PANEL_GID_LIST = {},
    PANEL_GATE_GID_LIST = {},
    LAST_PANEL_GID = FIRST_PANEL_GID + TOTAL_PANEL_GIDS - 1,
    updating = false,
    needs_disposal = false,
    disposal_promise = nil,
    is_liberated = false,
    honor_hp_mem = Net.get_area_custom_property(base_area_id, "Honor HPMem") == "true"
  }
  for i = 1, Net.get_layer_count(base_area_id), 1 do
    -- create a layer of panels
    mission.panels[i] = {}
    for j = 1, Net.get_layer_height(base_area_id), 1 do
      --Now we need to create the actual row of panels we'll be using within that layer.
      mission.panels[i][j] = {}
    end
  end
  setmetatable(mission, self)
  self.__index = self
  --Clone the area in to an instance with that nice randomized ID.
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

  local object_ids = Net.list_objects(mission.area_id)
  for _, object_id in ipairs(object_ids) do
    local object = Net.get_object_by_id(mission.area_id, object_id)
    if object.type == "Point of Interest" then
      -- track points of interest for the camera
      table.insert(mission.points_of_interest, object)
      -- delete to reduce map size
      Net.remove_object(mission.area_id, object_id)
    elseif is_panel(mission, object) then
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
      if object.type == "Item Panel" then
        -- set the loot for the panel
        if not includes(mission.ITEM_PANEL_GID_LIST, object.data.gid) then
          table.insert(mission.ITEM_PANEL_GID_LIST, object.data.gid)
          TOTAL_PANEL_GIDS = TOTAL_PANEL_GIDS + 1
        end
        --If it has a set drop, try to apply it.
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
          --If not, give it random loot from the basic pool.
          new_panel.loot = Loot.DEFAULT_POOL[math.random(#Loot.DEFAULT_POOL)]
        end
      elseif object.type == "Dark Hole" then
        -- track dark holes for converting indestructible panels
        if not includes(mission.DARK_HOLE_GID_LIST, object.data.gid) then
          table.insert(mission.DARK_HOLE_GID_LIST, object.data.gid)
          TOTAL_PANEL_GIDS = TOTAL_PANEL_GIDS + 1
        end

        table.insert(mission.dark_holes, new_panel)
      elseif object.type == "Indestructible Panel" then
        -- track indestructible panels for conversion
        if not includes(mission.INDESTRUCTIBLE_PANEL_GID_LIST, object.data.gid) then
          table.insert(mission.INDESTRUCTIBLE_PANEL_GID_LIST, object.data.gid)
          TOTAL_PANEL_GIDS = TOTAL_PANEL_GIDS + 1
        end

        table.insert(mission.indestructible_panels, new_panel)
      end
      if object.type == "Dark Panel" then
        if not includes(mission.BASIC_PANEL_GID_LIST, object.data.gid) then
          table.insert(mission.BASIC_PANEL_GID_LIST, object.data.gid)
          TOTAL_PANEL_GIDS = TOTAL_PANEL_GIDS + 1
        end
      elseif object.type == "Bonus Panel" then
        if not includes(mission.BONUS_PANEL_GID_LIST, object.data.gid) then
          table.insert(mission.BONUS_PANEL_GID_LIST, object.data.gid)
          TOTAL_PANEL_GIDS = TOTAL_PANEL_GIDS + 1
        end
      elseif object.type == "Trap Panel" then
        if not includes(mission.TRAP_PANEL_GID_LIST, object.data.gid) then
          table.insert(mission.TRAP_PANEL_GID_LIST, object.data.gid)
          TOTAL_PANEL_GIDS = TOTAL_PANEL_GIDS + 1
        end
      elseif object.type == "Panel Gate" then
        if not includes(mission.PANEL_GATE_GID_LIST, object.data.gid) then
          table.insert(mission.PANEL_GATE_GID_LIST, object.data.gid)
          TOTAL_PANEL_GIDS = TOTAL_PANEL_GIDS + 1
        end
        table.insert(mission.panel_gates, new_panel)
      end
      new_panel.id = Net.create_object(new_area_id, new_panel)
      new_panel.visual_object_id = object.id
      new_panel.visual_gid = object.data.gid
      -- insert the panel before spawning enemies
      local x = math.floor(object.x) + 1
      local y = math.floor(object.y) + 1
      local z = math.floor(object.z) + 1
      --Panel is at [layer][x coordinate][y coordinate] basically. It's easier to read it back in code that way.
      mission.panels[z][y][x] = new_panel

      -- spawning bosses
      if object.custom_properties.Boss then
        local name = object.custom_properties.Boss
        local direction = object.custom_properties.Direction
        local rank = object.custom_properties.Rank or 1
        local enemy = Enemy.from(mission, object, direction, name, rank)
        enemy.is_boss = true

        mission.boss = enemy
        table.insert(mission.enemies, 1, enemy) -- make the boss the first enemy in the list
      end

      -- spawning enemies
      if object.custom_properties.Spawns then
        local name = object.custom_properties.Spawns
        local direction = object.custom_properties.Direction
        local rank = object.custom_properties.Rank or 1
        local position = {
          x = object.x,
          y = object.y,
          z = object.z
        }

        position = EnemyHelpers.offset_position_with_direction(position, direction)

        local enemy = Enemy.from(mission, position, direction, name, rank)
        new_panel.enemy = enemy

        table.insert(mission.enemies, enemy) --Append the enemy to the list
      end
    end
  end

  -- print("mission start!")
  -- mission starts, so...

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
  self.resolve_disposal()

  return self.disposal_promise
end

function Mission:cleaning_up()
  return self.needs_disposal
end

function Mission:begin()
  local spawn = self:get_spawn_position()
  local hold_time = .7
  local slide_time = .7
  local total_camera_time = 0
  local start_health = 100
  local mhp = 100
  for _, player in ipairs(self.players) do
    -- create data
    self.player_sessions[player.id] = PlayerSession:new(self, player)
    if self.honor_hp_mem then
      mhp = player_data.get_player_max_health(player.id)

      Net.set_player_max_health(mhp)

      Net.set_player_health(player.id, mhp)
    else
      mhp = Net.get_player_max_health(player.id)
      Net.set_player_health(player.id, mhp)
    end
    self.player_sessions[player.id].max_health = Net.get_player_max_health(player.id)
    self.player_sessions[player.id].health = Net.get_player_health(player.id)

    if not debug then
      Net.lock_player_input(player.id)

      -- reset - we want the total camera time taken by all players in parallel, not in sequence
      total_camera_time = 0

      -- control camera
      Net.move_player_camera(player.id, spawn.x, spawn.y, spawn.z, hold_time)
      total_camera_time = total_camera_time + hold_time

      for j, point in ipairs(self.points_of_interest) do
        Net.slide_player_camera(player.id, point.x, point.y, point.z, slide_time)
        Net.move_player_camera(player.id, point.x, point.y, point.z, hold_time)

        total_camera_time = total_camera_time + slide_time + hold_time
      end

      Net.slide_player_camera(player.id, spawn.x, spawn.y, spawn.z, slide_time)

      total_camera_time = total_camera_time + slide_time
    end
  end

  if not debug then
    -- release players after camera animation
    Async.sleep(total_camera_time).and_then(function()
      for _, player in ipairs(self.players) do
        Net.unlock_player_camera(player.id)
        Net.unlock_player_input(player.id)
      end
    end)
  end
end

function Mission:on_tick(elapsed)
  if self.ready_count == #self.players then
    self.ready_count = 0
    -- If we're not done liberating the area, the enemies can take a turn!
    if not self.is_liberated then take_enemy_turn(self) end
  end

  self.emote_timer = self.emote_timer - elapsed

  for _, player_session in pairs(self.player_sessions) do
    if self.emote_timer <= 0 then
      player_session:emote_state()
      -- emote every second
      self.emote_timer = 1
    end
    if player_session.ability.name == "Shadowstep" then
      if player_session.player.moved then
        for x = -1, 1, 1 do
          for y = -1, 1, 1 do
            --Include a Z argument and fix layers. They're probably overlapping.
            --Konst says that this could lead to issues with a dark hole/panel/etc on a higher layer
            --not playing nice with one on a lower layer.
            local object = self:get_panel_at(player_session.player.x + x, player_session.player.y + y,
              player_session.player.z)
            if object and includes(shadowstep_table, object.type) and not self:get_enemy_at(object.x, object.y, object.z) then
              local object_id = object.id
              table.insert(player_session.shadowsteps, object_id)
              Net.exclude_object_for_player(player_session.player.id, object_id)
            end
          end
        end
      else
        local object = self:get_panel_at(player_session.player.x, player_session.player.y, player_session.player.z)
        if not object then
          for i = 1, #player_session.shadowsteps, 1 do
            local panel_id = player_session.shadowsteps[i]
            Net.include_object_for_player(player_session.player.id, panel_id)
          end
          player_session.shadowsteps = {}
        end
      end
    end
  end
end

function Mission:handle_tile_interaction(player_id, x, y, z, button)
  local player_session = self.player_sessions[player_id]
  local object = self:get_panel_at(player_session.player.x, player_session.player.y, player_session.player.z)

  if object then return end

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
  if player_session == nil then return end;

  local x, y, z = player_session.player.x, player_session.player.y, player_session.player.z
  local object = self:get_panel_at(x, y, z)

  -- Player is moving over dark panels with an ability and thus cannot interact.
  if object then return end

  if button == 1 then
    -- Shoulder L
    return
  end

  if player_session.completed_turn or Net.is_player_in_widget(player_id) then
    -- ignore selection as it's not our turn or waiting for a response
    return
  end

  -- panel selection detection
  object = Net.get_object_by_id(self.area_id, object_id)

  -- If it no longer exists, it must have been liberated.
  if not object then return self:handle_tile_interaction(player_id, x, y, z, button) end

  if not is_adjacent(
        {
          x = player_session.player.x,
          y = player_session.player.y,
          z = player_session.player.z
        },
        {
          x = object.x,
          y = object.y,
          z = object.z
        }
      ) then
    -- can't select panels diagonally
    print("diagonal")
    return
  end

  local panel = self:get_panel_at(object.x, object.y, object.z)

  if not panel then
    -- no data associated with this object
    print("no panel somehow")
    return
  end

  Net.lock_player_input(player_id)

  local panel_already_selected = false

  for _, check_player_session in pairs(self.player_sessions) do
    if check_player_session.selection.root_panel == panel then
      panel_already_selected = true
      break
    end
  end

  local can_liberate = not panel_already_selected and (
    panel.type == "Dark Panel" or
    panel.type == "Item Panel" or
    panel.type == "Dark Hole" or
    panel.type == "Bonus Panel" or
    panel.type == "Trap Panel"
  )

  if not can_liberate then
    -- indestructible panels
    local quiz_promise = player_session:quiz_with_points("Pass", "Cancel")

    quiz_promise.and_then(function(response)
      if response == 0 then     -- Pass
        player_session:get_pass_turn_permission()
      elseif response == 1 then -- Cancel
        Net.unlock_player_input(player_id)
      end
    end)

    return
  end

  local ability = player_session.ability

  local has_enemy = false

  -- Check for existence of an enemy.
  for _, enemy in ipairs(self.enemies) do
    if (math.min(panel.x) == enemy.x and math.min(panel.y) == enemy.y and enemy.z == panel.z) then
      has_enemy = true
      break
    end
  end

  local can_use_ability = (
    ability ~= nil and
    ability.question and -- no question = passive ability
    not has_enemy and    -- cant have an enemy standing on this tile
    self.order_points >= ability.cost and
    (
      panel.type == "Dark Panel" or
      panel.type == "Item Panel" or
      panel.type == "Trap Panel"
    )
  )

  local quiz_promise = nil;

  if can_use_ability == false then
    quiz_promise = player_session:quiz_with_points(
      "Liberation",
      "Pass",
      "Cancel"
    )
  else
    quiz_promise = player_session:quiz_with_points(
      "Liberation",
      ability.name,
      "Pass"
    )
  end

  player_session.selection:select_panel(panel)

  quiz_promise.and_then(function(response)
    if response == 0 then
      -- Liberation
      liberate_panel(self, player_session).and_then(function(result)
        -- Return control to the player
        -- Net.unlock_player_input(player_id)

        -- Always last! Complete the turn to progress the mission!
        -- player_session:complete_turn()
      end)
    elseif (response == 1 and can_use_ability == false) or (response == 2 and can_use_ability == true) then
      -- Pass
      player_session.selection:clear()
      player_session:get_pass_turn_permission()
    elseif response == 1 and can_use_ability == true then
      -- Ability
      local selection_shape, shape_offset_x, shape_offset_y = ability.generate_shape(self, player_session)
      player_session.selection:set_shape(selection_shape, shape_offset_x, shape_offset_y)

      -- ask if we should use the ability
      player_session:get_ability_permission()
    elseif (response == 2 and can_use_ability == false) then
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

function Mission:handle_player_transfer(player_id)
end

function Mission:handle_player_disconnect(player_id)
  for i, player in ipairs(self.players) do
    if player_id == player.id then
      table.remove(self.players, i)
      break
    end
  end
  if self and self.player_sessions then
    self.player_sessions[player_id]:handle_disconnect()
    self.player_sessions[player_id] = nil
  end
end

function Mission:get_players()
  return self.players
end

function Mission:get_spawn_position()
  return Net.get_object_by_name(self.area_id, "Spawn")
end

function Mission:get_next_spawn_from_object(object_id)
  local object = Net.get_object_by_id(self.area_id, object_id)
  if object.custom_properties["Next Spawn"] and Net.get_object_by_id(self.area_id, tonumber(object.custom_properties["Next Spawn"])).type == "Spawn Point" then
    return Net.get_object_by_id(self.area_id, tonumber(object.custom_properties["Next Spawn"]))
  end
  return self:get_spawn_position()
end

-- helper functions
function Mission:get_panel_at(x, y, z)
  if not self.panels or #self.panels == 0 then return nil end
  y = math.floor(y) + 1
  z = math.floor(z) + 1
  local row = self.panels[z][y]

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

  if panel.type == "Dark Hole" then
    print("deleting dark hole")
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
