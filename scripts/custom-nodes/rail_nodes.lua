local player_data = require('scripts/custom-scripts/player_data')

local PROG_TEXTBOX_OPTIONS = {
  mug = {
    texture_path = "/server/assets/mugs/prog.png",
    animation_path = "/server/assets/mugs/shared_mug.animation",
  }
}

---@param scripts ScriptNodes
return function(scripts)
  scripts:implement_node("Give RailPass", function(context, node_object)
    local player_id = context.player_id
    local player_memory = player_data.get_player_data(player_id)

    Net.lock_player_input(player_id)
    Net.message_player(player_id, "HELLO!", PROG_TEXTBOX_OPTIONS)

    Async.create_scope(function()
      if player_memory.event_data["NebulaBattle1Finished"] ~= true then
        Net.message_player(player_id, "WE ARE CURRENTLY EXPERIENCING SERVICE INTERRUPTIONS.", PROG_TEXTBOX_OPTIONS)
        Async.await(Async.message_player(player_id, "PLEASE CHECK BACK LATER!", PROG_TEXTBOX_OPTIONS))
      else
        Net.message_player(player_id, "WE ARE ONCE AGAIN OPEN FOR BUSINESS!", PROG_TEXTBOX_OPTIONS)
        Net.message_player(player_id, "SORRY ABOUT THAT.", PROG_TEXTBOX_OPTIONS)
        Net.message_player(player_id, "SOME HOOLIGANS WERE BLOCKING THE RAILS! IT'S CLEARED UP NOW.",
          PROG_TEXTBOX_OPTIONS)
        Net.message_player(player_id, "INSTEAD OF RELYING ON THOSE OLD TRAMS, WE NOW OFFER A TELEPORT SERVICE!",
          PROG_TEXTBOX_OPTIONS)
        Async.await(Async.message_player(player_id, "HERE'S YOUR COMMEMORATIVE RAIL PASS!", PROG_TEXTBOX_OPTIONS))

        player_data.update_player_item(player_id, "RailPass", 1)
      end

      Net.unlock_player_input(player_id)

      scripts:execute_next_node(context, context.area_id, node_object)
    end)
  end)

  scripts:implement_node("Conductor Teleport", function(context, node_object)
    local area_id = node_object.custom_properties["Warp Map"]
    local object = Net.get_object_by_name(context.area_id, "Conductor Warp")
    local direction = object.custom_properties["Direction"] or Net.get_player_direction(context.player_id)
    Net.transfer_player(context.player_id, area_id, true, object.x, object.y, object.z, direction)

    scripts:execute_next_node(context, context.area_id, node_object)
  end)
end
