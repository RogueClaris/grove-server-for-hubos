local Player = {}

function Player:new(player_id)
  local position = Net.get_player_position(player_id)

  local player = {
    id = player_id,
    activity = nil,
    mug = Net.get_player_mugshot(player_id),
    textbox_promise_resolvers = {},
    resolve_battle = nil,
    avatar_details = nil,
    moved = false,
    x = position.x,
    y = position.y,
    z = position.z,
    disconnected = false
  }

  setmetatable(player, self)
  self.__index = self

  return player
end

function Player:message(message, texture_path, animation_path)
  return Async.message_player(self.id, message, texture_path, animation_path)
end

function Player:message_auto(message, close_delay, texture_path, animation_path)
  return Async.message_player_auto(self.id, message, close_delay, texture_path, animation_path)
end

function Player:message_with_mug(message)
  return self:message(message, self.mug.texture_path, self.mug.animation_path)
end

function Player:question(question, texture_path, animation_path)
  return Async.question_player(self.id, question, texture_path, animation_path)
end

function Player:question_with_mug(question)
  return self:question(question, self.mug.texture_path, self.mug.animation_path)
end

function Player:quiz(a, b, c, texture_path, animation_path)
  return Async.quiz_player(self.id, a, b, c, texture_path, animation_path)
end

function Player:is_battling()
  return self.resolve_battle ~= nil
end

-- will throw if a textbox is sent to the player using Net directly
function Player:handle_textbox_response(response)
  -- if self.activity ~= nil then
  -- if response == nil then return end;
  local resolve = table.remove(self.textbox_promise_resolvers, 1)

  --may cause silent errors in liberation stuff.
  --maybe undo this change (if resolve ~= nil) when debugging.
  if resolve ~= nil then
    resolve(response)
  else
    print('resolve was nil')
  end
  -- end
end

function Player:handle_battle_results(stats)
  if not self.resolve_battle then
    return
  end
  local resolve = self.resolve_battle
  self.resolve_battle = nil

  resolve(stats)
end

function Player:handle_disconnect()
  self.disconnected = true

  for _, resolve in ipairs(self.textbox_promise_resolvers) do
    resolve()
  end

  if self.resolve_battle then
    self:handle_battle_results(create_default_results())
  end

  self.textbox_promise_resolvers = nil

  if self.activity then
    self.activity:handle_player_disconnect(self.id)
  end
end

function Player:boot_to_lobby(isVictory, mapName)
  self.activity:handle_player_disconnect(self.id)
  self.activity = nil
  local area_id = Net.get_player_area(self.id)
  local respawn_area = Net.get_area_custom_property(area_id, "Respawn Area")
  local spawn = nil

  if respawn_area ~= nil then
    spawn = Net.get_object_by_name(respawn_area, "Liberation Respawn")
  else
    respawn_area = "default"
    spawn = Net.get_spawn_position("default")
  end

  Net.transfer_player(self.id, respawn_area, true, spawn.x, spawn.y, spawn.z)

  if isVictory then
    local gate_to_remove = nil
    for index, value in ipairs(Net.list_objects(respawn_area)) do
      local prospective_gate = Net.get_object_by_id(respawn_area, value)
      if prospective_gate.custom_properties["Liberation Map Name"] == mapName then
        gate_to_remove = prospective_gate
        break
      end
    end
    if gate_to_remove ~= nil then
      player_data.hide_target_from_player(self.id, respawn_area, gate_to_remove.id, "OBJECT", true)
    end
  end

  player_data.update_player_current_health(self.id, player_data.get_player_max_health(self.id))
end

return Player
