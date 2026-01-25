local player_data = require('scripts/custom-scripts/player_data')

---@param scripts ScriptNodes
return function(scripts)
  scripts:implement_node("Get Yai Code", function(context, node_object)
    local player_id = context.player_id

    Net.lock_player_input(player_id)
    Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 255 }, 1)

    if player_data.count_player_item(player_id, "YaiCode") == 0 then
      player_data.update_player_item(player_id, "YaiCode", 1)
    end

    Async.create_scope(function()
      Async.await(Async.sleep(1))

      player_data.hide_target_from_player(player_id, Net.get_player_area(player_id), context.bot_id, "ACTOR", true)

      Net.unlock_player_input(player_id)
      Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 0 }, 1)

      scripts:execute_next_node(context, context.area_id, node_object)
    end)
  end)

  scripts:implement_node("Get Yai Data", function(context, node_object)
    local player_id = context.player_id

    Net.lock_player_input(player_id)
    Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 255 }, 1)

    if player_data.count_player_item(player_id, "YaiData") == 0 then
      player_data.update_player_item(player_id, "YaiData", 1)
    end

    Async.create_scope(function()
      Async.await(Async.sleep(1))

      player_data.hide_target_from_player(player_id, Net.get_player_area(player_id), context.bot_id, "ACTOR", true)

      Net.unlock_player_input(player_id)
      Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 0 }, 1)

      scripts:execute_next_node(context, context.area_id, node_object)
    end)
  end)

  scripts:implement_node("GlydeProgQuest", function(context, node_object)
    local player_memory = player_data.get_player_data(context.player_id)
    local quests = player_memory.quest_data

    if quests == nil then
      quests = {}
      player_memory.quest_data = quests
    end

    local quest = quests["YaiHomework"]

    if quest == nil then
      quest = {
        started = false,
        completed = false,
        repeatable = false,
        rewards = {
          {
            type = "keyitem",
            name_or_id = "YaiCode"
          },
          {

          }
        },
        flags = {}
      }
      quests["YaiHomework"] = quest
    end

    if quest.completed == true then return end

    quest.started = true
  end)
end
