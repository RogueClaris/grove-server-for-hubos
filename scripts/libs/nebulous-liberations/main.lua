local player_data = require('scripts/custom-scripts/player_data')
local Instance = require("scripts/libs/nebulous-liberations/liberations/instance")
local Ability = require("scripts/libs/nebulous-liberations/liberations/ability")
local Parties = require("scripts/libs/nebulous-liberations/utils/parties")

local Liberations = {}

local waiting_area_map = {}
local gate_to_area_map = {}

local function transfer_players_to_new_instance(base_area, player_ids)
  local instance = Instance:new(base_area, "test")

  for _, player_id in ipairs(player_ids) do
    -- resolve ability
    local ability = Ability.LongSwrd

    for _, ability_value in ipairs(Ability.ALL) do
      if player_data.count_player_item(player_id, ability_value.name) > 0 then
        ability = ability_value
        break
      end
    end

    -- transfer player
    instance:transfer_player(player_id, ability)
  end

  instance.events:on("money", function(event)
    player_data.update_player_money(event.player_id, event.money)
  end)
end

function Liberations.start_game_for_player(player_id, liberation_id)
  local party = Parties.find(player_id)
  if party == nil then
    transfer_players_to_new_instance(liberation_id, { player_id })
  else
    transfer_players_to_new_instance(liberation_id, party.members)
  end
end

local function detect_door_interaction(player_id, object_id, button)
  if button ~= 0 then return end
  local missionArea = gate_to_area_map[object_id]
  local player_area = Net.get_player_area(player_id)

  if missionArea ~= nil and player_area == missionArea[1] then
    local mug_option = { mug = Net.get_player_mugshot(player_id) }

    Async.question_player(player_id, "Start mission?", mug_option).and_then(function(response)
      if response == 1 then
        Liberations.start_game_for_player(player_id, missionArea[2])
      end
    end)
  end
end

---@param player_id Net.ActorId
local function leave_party(player_id)
  local party = Parties.find(player_id)

  if not party then
    return
  end

  Parties.leave(player_id)

  -- let everyone know you left
  local name = Net.get_player_name(player_id)

  for _, member_id in ipairs(party.members) do
    Net.message_player(member_id, name .. " has left your party.")
  end

  if #party.members == 1 then
    Net.message_player(party.members[1], "Party disbanded!")
  end
end

Net:on("object_interaction", function(event)
  local button = event.button
  local player_id = event.player_id
  local object_id = event.object_id
  local area_id = Net.get_player_area(player_id)

  if waiting_area_map[area_id] ~= nil then
    detect_door_interaction(player_id, object_id, button)
  end
end)

Net:on("actor_interaction", function(event)
  local player_id = event.player_id
  local button = event.button
  local other_player_id = event.actor_id
  local area_id = Net.get_player_area(player_id)

  if waiting_area_map[area_id] == nil or button ~= 0 then return end

  if Net.is_bot(other_player_id) then return end

  local name = Net.get_player_name(other_player_id)

  local mug_option = { mug = Net.get_player_mugshot(player_id) }

  if Parties.is_in_same_party(player_id, other_player_id) then
    Net.message_player(player_id, name .. " is already in our party.", mug_option)
    return
  end

  -- checking for an invite
  if Parties.has_request(player_id, other_player_id) then
    -- other player has a request for us
    Async.question_player(player_id, "Join " .. name .. "'s party?", mug_option).and_then(function(response)
      if response == 1 then
        Parties.accept(player_id, other_player_id)
      end
    end)

    return
  end

  -- try making a party request
  if Parties.has_request(other_player_id, player_id) then
    Async.message_player(player_id, "We already asked " .. name .. " to join our party.", mug_option)
    return
  end

  Async.question_player(player_id, "Recruit " .. name .. "?", mug_option).and_then(function(response)
    if response == 1 then
      -- create a request
      Parties.request(player_id, other_player_id)
    end
  end)
end)

Net:on("player_disconnect", function(event)
  leave_party(event.player_id)
end)

local respawn_table = {}

local areas = Net.list_areas()
for i, area_id in next, areas do
  local objects = Net.list_objects(area_id)
  local custom_parameters = Net.get_area_custom_properties(area_id)
  if custom_parameters["Respawn Area"] then
    respawn_table[area_id] = custom_parameters["Respawn Area"]
    if custom_parameters["Waiting Area"] then
      waiting_area_map[custom_parameters["Waiting Area"]] = area_id
    else
      waiting_area_map[custom_parameters["Respawn Area"]] = area_id
    end
  end
  for index, value in ipairs(objects) do
    local object = Net.get_object_by_id(area_id, value)
    if object.custom_properties["Liberation Map File Name"] then
      gate_to_area_map[value] = { area_id, object.custom_properties["Liberation Map File Name"] }
    end
  end
end

return Liberations
