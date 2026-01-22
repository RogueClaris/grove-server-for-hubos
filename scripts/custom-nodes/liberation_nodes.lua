local LibPlugin = require('scripts/custom-scripts/liberations')
local player_data = require('scripts/custom-scripts/player_data')

---@param scripts ScriptNodes
return function(scripts)
  scripts:implement_node("Grant Liberation Mission Ability", function(context, node_object)
    if node_object.custom_properties["Ability Item"] ~= nil then
      player_data.update_player_item(context.player_id, node_object.custom_properties["Ability Item"], 1)
    end

    scripts:execute_next_node(context, context.area_id, node_object)
  end)

  scripts:implement_node("Refight Liberation", function(context, node_object)
    LibPlugin.start_game_for_player(context.player_id, node_object.custom_properties["Liberation Map"])
  end)
end
