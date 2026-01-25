---@class Checkpoint
---@field x number
---@field y number
---@field z number
---@field area_id string
---@field show_checkpoint boolean

---@class PlayerData
---@field health PlayerHealthData
---@field event_data table<string, any>
---@field quest_data table<string, any>?
---@field money number
---@field items table<string, number?>
---@field hidden_things HiddenThingMaps
---@field login_location Checkpoint?
---@field whitelist_path string?
---@field io_whitelist_path string?
---@field joins number

---@class PlayerHealthData
---@field navi_current number
---@field navi_base number number
---@field server_current number
---@field server_base number

---@class HiddenThingData
---@field hidden boolean
---@field permanent boolean
---@field hide_type "ACTOR" | "OBJECT"
---@field id any

---@alias HiddenThingMap table<string, table<any, HiddenThingData>>

---@class HiddenThingMaps
---@field OBJECT HiddenThingMap
---@field ACTOR HiddenThingMap
---@field PLAYER HiddenThingMap

local PlayerData = {}

local DataStorage = require("scripts/libs/data_storage")

DataStorage.init()

local function create_player_data()
  return {
    health = {
      navi_current = 100,
      navi_base = 100,
      server_current = 100,
      server_base = 100
    },
    items = {},
    money = 0,
    event_data = {},
    hidden_things = { OBJECT = {}, ACTOR = {}, PLAYER = {} },
    login_location = nil,
    whitelist_path = nil,
    io_whitelist_path = nil,
    joins = 0
  }
end

--- inspired by lodash's _.set()
---
--- `set(object, key1, key2, ..., value)`
---
--- similar to `object[key1][key2][key3] = value`, but without indexing errors
local function set(t, ...)
  local o = t

  local total_varargs = select("#", ...)

  for i = 1, total_varargs - 2 do
    local key = select(i, ...)
    local next_o = o[key]

    if not next_o then
      next_o = {}
      o[key] = next_o
    end

    o = next_o
  end

  o[select(total_varargs - 1, ...)] = select(total_varargs, ...)
end

--- inspired by lodash's _.get()
---
--- `get(object, key1, key2, ...)`
---
--- similar to `object[key1][key2][key3]`, but without indexing errors
local function get(t, ...)
  local o = t

  local total_varargs = select("#", ...)

  for i = 1, total_varargs do
    if not o then
      return nil
    end

    local key = select(i, ...)
    o = o[key]
  end

  return o
end

---@param player_id Net.ActorId
---@return PlayerData
PlayerData.get_player_data = function(player_id)
  -- load sync to work outside of async functions (accesses cache if it's already loaded)
  return DataStorage.load_sync(Net.get_player_secret(player_id), create_player_data)
end

Net:on("player_avatar_change", function(event)
  local player_id = event.player_id
  local data = PlayerData.get_player_data(player_id)
  if data.joins > 1 then
    PlayerData.sync_player_health(player_id)
  end
end)

PlayerData.sync_player_health = function(player_id)
  local data = PlayerData.get_player_data(player_id)

  local server_base = data.health.server_base

  local old_navi_current = data.health.navi_current
  local old_navi_base = data.health.navi_base

  local new_navi_max = Net.get_player_max_health(player_id)
  local new_navi_base = Net.get_player_base_health(player_id)

  local aug_boost
  if new_navi_base ~= new_navi_max then
    aug_boost = new_navi_max - new_navi_base
    new_navi_base = new_navi_max - aug_boost
  end



  local percent = (old_navi_current / old_navi_base)
  local new_current_health = new_navi_base * percent

  data.health.navi_current = new_current_health
  data.health.navi_base = new_navi_base

  Net.set_player_base_health(player_id, server_base)
  Net.set_player_health(player_id, new_current_health)

  PlayerData.save_player_data(player_id)
end

PlayerData.boost_player_max_health = function(player_id, amount)
  local data = PlayerData.get_player_data(player_id)

  data.health.server_base = data.health.server_base + amount

  PlayerData.save_player_data(player_id)
end

PlayerData.get_player_max_health = function(player_id)
  return PlayerData.get_player_data(player_id).health.server_base
end

PlayerData.update_player_current_health = function(player_id, amount)
  local data = PlayerData.get_player_data(player_id)

  data.health.server_current = math.min(data.health.server_base, data.health.server_current + amount)

  Net.set_player_health(player_id, data.health.server_current)

  PlayerData.save_player_data(player_id)
end

PlayerData.count_player_item = function(player_id, item_id)
  local data = PlayerData.get_player_data(player_id)
  local player_items = data.items
  local item_amount = player_items[item_id]

  if type(item_amount) ~= "number" then return 0 end

  return item_amount
end

PlayerData.count_player_money = function(player_id)
  local data = PlayerData.get_player_data(player_id)
  return data.money
end

PlayerData.update_player_item = function(player_id, item_id, count)
  local data = PlayerData.get_player_data(player_id)
  local amount = PlayerData.count_player_item(player_id, item_id)

  local player_items = data.items
  player_items[item_id] = math.max(0, amount + count)

  Net.give_player_item(player_id, item_id, count)

  PlayerData.save_player_data(player_id)
end

PlayerData.update_player_money = function(player_id, money)
  local data = PlayerData.get_player_data(player_id)

  -- Use addition, since inputting negative will spend
  data.money = data.money + money

  Net.set_player_money(player_id, data.money)

  PlayerData.save_player_data(player_id)
end

PlayerData.is_target_hidden = function(player_id, area_id, target_id, target_type)
  -- convert to string for the json lib
  target_id = tostring(target_id)

  local data = PlayerData.get_player_data(player_id)
  local target_list
  if target_type == "ACTOR" then
    target_list = data.hidden_things.ACTOR
  elseif target_type == "OBJECT" then
    target_list = data.hidden_things.OBJECT
  else
    print("[PlayerData] Value of argument 'target_type' was invalid in function 'is_target_hidden'.")
    return nil
  end

  local result = false
  local target = get(target_list, area_id, target_id)
  if target ~= nil and target.hidden == true then result = true end

  return result
end

PlayerData.reveal_target_to_player = function(player_id, area_id, target_id, target_type, revert_permanence)
  -- convert to string for the json lib
  local raw_target_id = target_id
  target_id = tostring(target_id)

  -- Not hidden, don't need to reveal through this function
  if PlayerData.is_target_hidden(player_id, area_id, target_id, target_type) == false then return end

  if target_type ~= "ACTOR" and target_type ~= "OBJECT" then
    print("[PlayerData] Value of argument 'target_type' was invalid in function 'reveal_target_to_player'.")
    return
  end

  local data = PlayerData.get_player_data(player_id)
  local target

  if target_type == "ACTOR" then
    target = data.hidden_things.ACTOR[area_id][target_id]

    Net.include_actor_for_player(player_id, raw_target_id)
  elseif target_type == "OBJECT" then
    local object = Net.get_object_by_id(area_id, target_id)

    target = data.hidden_things.OBJECT[area_id][target_id]

    Net.include_object_for_player(player_id, object.id)
  end

  target.hidden = false

  if revert_permanence == true and target.hide_permanently == true then
    target.hide_permanently = false
  end

  PlayerData.save_player_data(player_id)
end

PlayerData.hide_target_from_player = function(player_id, area_id, target_id, target_type, hide_permanently)
  -- if target_type == "PLAYER" then
  --   PlayerData.hide_player_from_other_player(player_id, target_id, hide_permanently)
  --   return
  -- end

  -- convert to string for the json lib
  local raw_target_id = target_id
  target_id = tostring(target_id)

  if target_type ~= "ACTOR" and target_type ~= "OBJECT" then
    print("[PlayerData] Value of argument 'target_type' was invalid in function 'hide_target_from_player'.")
    return
  end

  if hide_permanently == nil then hide_permanently = false end

  local data = PlayerData.get_player_data(player_id)

  ---@type HiddenThingData
  local hide_data = {
    hidden = true,
    permanent = hide_permanently,
    hide_type = target_type,
    id = raw_target_id
  }

  if target_type == "OBJECT" then
    local object = Net.get_object_by_id(area_id, target_id)

    -- Object is nil, do nothing + warn
    if object == nil then
      print(
        "[PlayerData]\nAttempted to hide object with ID " ..
        tostring(target_id) .. " in area " .. Net.get_area_name(area_id) .. ", but object was nil."
      )
      return
    end

    Net.exclude_object_for_player(player_id, object.id)
  elseif target_type == "ACTOR" then
    Net.exclude_actor_for_player(player_id, raw_target_id)
  end

  set(data.hidden_things, target_type, area_id, target_id, hide_data)

  PlayerData.save_player_data(player_id)
end

-- PlayerData.hide_player_from_other_player = function(player_id, target_id, hide_permanently) end

PlayerData.set_event_flag = function(player_id, flag, value)
  local data = PlayerData.get_player_data(player_id)
  local player_event_data = data.event_data

  player_event_data[flag] = value

  PlayerData.save_player_data(player_id)
end

PlayerData.update_join_count = function(player_id)
  local data = PlayerData.get_player_data(player_id)
  data.joins = data.joins + 1
  PlayerData.save_player_data(player_id)
end

PlayerData.get_join_count = function(player_id)
  local data = PlayerData.get_player_data(player_id)
  return data.joins
end

PlayerData.get_event_flag = function(player_id, flag, default)
  local data = PlayerData.get_player_data(player_id)
  local player_event_data = data.event_data
  if player_event_data[flag] == nil and default ~= nil then
    player_event_data[flag] = default
    PlayerData.save_player_data(player_id)
  elseif player_event_data[flag] ~= nil then
    return player_event_data[flag]
  end

  return default
end

---@param player_id Net.ActorId
PlayerData.save_player_data = function(player_id)
  local key = Net.get_player_secret(player_id)
  local data = DataStorage.load_sync(key)
  DataStorage.store(key, data)
end

Net:on("player_connect", function(event)
  local data = PlayerData.get_player_data(event.player_id)

  if data == nil then
    print("[PlayerData] data was nil, is this their first join?")
    return
  end

  PlayerData.update_join_count(event.player_id)

  -- load async on join to avoid freezing on first read
  DataStorage.load(Net.get_player_secret(event.player_id), create_player_data)
      .and_then(function(loaded_data)
        for item_id, count in pairs(loaded_data.items) do
          Net.give_player_item(event.player_id, item_id, count)
        end

        if loaded_data.joins == 1 then
          Net.set_player_base_health(event.player_id, 100)
          Net.set_player_health(event.player_id, 100)

          data.cards = {}
          data.augments = {}

          Net.give_player_block(event.player_id, "BattleNetwork6.Program13.UnderShirt", "white", 1)

          Net.give_player_card(event.player_id, "BattleNetwork6.CannonBase", "*", -1)

          Net.give_player_card(event.player_id, "BattleNetwork6.Class01.Standard.001", "A", 2) -- Cannon A,     40 dmg each
          Net.give_player_card(event.player_id, "BattleNetwork6.Class01.Standard.001", "B", 2) -- Cannon B,     40 dmg each
          Net.give_player_card(event.player_id, "BattleNetwork6.Class01.Standard.002", "L", 1) -- HiCannon L,   100 dmg
          Net.give_player_card(event.player_id, "BattleNetwork6.Class01.Standard.004", "*", 2) -- AirShot *,    20 damage each
          Net.give_player_card(event.player_id, "BattleNetwork6.Class01.Standard.005", "S", 2) -- Vulcan1 S,    10~30 damage each
          Net.give_player_card(event.player_id, "BattleNetwork6.Class01.Standard.009", "L", 4) -- Spreader L,   30 AoE damage each
          Net.give_player_card(event.player_id, "BattleNetwork6.Class01.Standard.018", "L", 2) -- YoYo L,       50 damage per hit, max 150 per chip
          Net.give_player_card(event.player_id, "BattleNetwork6.Class01.Standard.058", "B", 4) -- MiniBomb B,   40 dmg each
          Net.give_player_card(event.player_id, "BattleNetwork6.Class01.Standard.070", "S", 2) -- Sword S,      80 damage each
          Net.give_player_card(event.player_id, "BattleNetwork6.Class01.Standard.071", "S", 1) -- WideSword S,  80 damage
          Net.give_player_card(event.player_id, "BattleNetwork6.Class01.Standard.072", "S", 1) -- LongSword S,  80 damage
          Net.give_player_card(event.player_id, "BattleNetwork6.Class01.Standard.138", "*", 2) -- RockCube *,   200 damage each, if pushed
          Net.give_player_card(event.player_id, "BattleNetwork6.Class01.Standard.156", "*", 2) -- Recov10 *,    +10 HP each
          Net.give_player_card(event.player_id, "BattleNetwork6.Class01.Standard.157", "*", 1) -- Recov30 *,    +30 HP
          Net.give_player_card(event.player_id, "BattleNetwork6.Class01.Standard.164", "*", 2) -- PanlGrab *,   10 damage, if blocked
        end

        if type(loaded_data.money) == "number" then
          Net.set_player_money(event.player_id, loaded_data.money)
        end
      end)
end)

Net:on("player_disconnect", function(event)
  local player_id = event.player_id
  local data = PlayerData.get_player_data(player_id)

  local area_list = Net.list_areas()
  for _, area in ipairs(area_list) do
    local target_list = data.hidden_things[area]

    if target_list == nil then goto outer_continue end
    if #target_list == 0 then goto outer_continue end

    for _, value in ipairs(target_list) do
      if value.hidden ~= true then goto inner_continue end

      if value.hide_permanently ~= true then
        value.hidden = false
      end

      ::inner_continue::
    end
    ::outer_continue::
  end

  -- unload to clear from cache
  DataStorage.unload(Net.get_player_secret(player_id))
end)


local function restore_area_state(event)
  local player_id = event.player_id
  local data = PlayerData.get_player_data(player_id)
  local area = Net.get_player_area(player_id)

  local target_list = data.hidden_things.ACTOR[area] or {}
  for _, target in pairs(target_list) do
    if target.hidden == true then

    end
  end

  local target_list = data.hidden_things.OBJECT[area] or {}
  for _, target in pairs(target_list) do
    if target.hidden == true then
      Net.exclude_object_for_player(player_id, target.id)
    end
  end
end

Net:on("player_area_transfer", restore_area_state)
Net:on("player_join", restore_area_state)

return PlayerData
