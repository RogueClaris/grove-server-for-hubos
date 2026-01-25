local naviNames = require('scripts/custom-scripts/navi_names')
local player_data = require('scripts/custom-scripts/player_data')

local GUTS_MUG = {
  mug = {
    texture_path = "/server/assets/mugs/gutsman.png",
    animation_path = "/server/assets/mugs/shared_mug.animation"
  }
}

---@param scripts ScriptNodes
return function(scripts)
  scripts:implement_node("Gutsman Battle", function(context, node_object)
    local player_id = context.player_id

    local promise = Async.initiate_encounter(player_id, "/server/assets/encounters/dependencies/com_Thor_Gutsman_V1.zip")

    promise.and_then(function(results)
      if not results or results.ran or results.health <= 0 then
        return
      end

      player_data.update_player_item(player_id, "GutsProof", 1)

      Net.message_player(player_id, "N-No way, guts!", GUTS_MUG)
      Net.message_player(player_id, "Y-You're dead,\n" .. naviNames.player_navi_names[player_id] .. "!", GUTS_MUG)

      scripts:execute_next_node(context, context.area_id, node_object)
    end)
  end)

  scripts:implement_node("Gutsman V2 Battle", function(context, node_object)
    local player_id = context.player_id

    local promise = Async.initiate_encounter(player_id, "/server/assets/encounters/dependencies/com_Thor_Gutsman_V2.zip")

    promise.and_then(function(results)
      if not results or results.ran or results.health <= 0 then
        return
      end

      player_data.update_player_item(player_id, "GutsProof", 1)

      Net.message_player(player_id, "S-So shameful, guts...!", GUTS_MUG)
      Net.message_player(player_id, "H-How are you\nso strong,\n" ..
        naviNames.player_navi_names[player_id] .. "!?", GUTS_MUG)

      scripts:execute_next_node(context, context.area_id, node_object)
    end)
  end)

  scripts:implement_node("Gutsman V3 Battle", function(context, node_object)
    local player_id = context.player_id

    local promise = Async.initiate_encounter(player_id, "/server/assets/encounters/dependencies/com_Thor_Gutsman_V3.zip")

    promise.and_then(function(results)
      if not results or results.ran or results.health <= 0 then
        return
      end

      player_data.update_player_item(player_id, "GutsProof", 1)

      Net.message_player(player_id, "I-I'll get you next time, guts!", GUTS_MUG)

      scripts:execute_next_node(context, context.area_id, node_object)
    end)
  end)

  scripts:implement_node("Gutsman V4 Battle", function(context, node_object)
    local player_id = context.player_id

    local promise = Async.initiate_encounter(player_id, "/server/assets/encounters/dependencies/com_Thor_Gutsman_V4.zip")

    promise.and_then(function(results)
      if not results or results.ran or results.health <= 0 then
        return
      end

      player_data.update_player_item(player_id, "GutsProof", 1)

      Net.message_player(player_id, "...\n\n\nYou really get me, guts! Take this.", GUTS_MUG)
      Net.message_player(player_id, "You got Guts Hammer! Use it in liberations.")

      local count = player_data.count_player_item(player_id, "GutsHamr")

      if count > 0 then return end

      player_data.update_player_item(player_id, "GutsHamr", 1)

      scripts:execute_next_node(context, context.area_id, node_object)
    end)
  end)
end
