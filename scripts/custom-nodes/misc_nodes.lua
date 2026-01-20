local ezshortcuts = require('scripts/custom-scripts/ezshortcuts')
local naviNames = require('scripts/custom-scripts/navi_names')
local player_data = require('scripts/custom-scripts/player_data')

---@param scripts ScriptNodes
return function(scripts)
  scripts:implement_node("Create Checkpoint", function(context, node_object)
    local player_id = context.player_id
    local pos = Net.get_player_position(player_id)
    ezshortcuts.create_checkpoint(player_id, pos.x, pos.y, pos.z, false)

    scripts:execute_next_node(context, context.area_id, node_object)
  end)

  scripts:implement_node("Playdome Playtime", function(context, node_object)
    local player_id = context.player_id

    local area_id = Net.get_player_area(player_id)
    local object = Net.get_object_by_id(area_id, context.object_id)
    Net.lock_player_input(player_id)
    Net.move_player_camera(player_id, object.x, object.y, object.z, 5)
    Net.exclude_actor_for_player(player_id, player_id)

    Async.sleep(5).and_then(function()
      Net.unlock_player_camera(player_id)
      Net.include_actor_for_player(player_id, player_id)
      Net.unlock_player_input(player_id)

      scripts:execute_next_node(context, context.area_id, node_object)
    end)
  end)

  scripts:implement_node("Remove Bass ACDC 4", function(context, node_object)
    local player_id = context.player_id

    Net.lock_player_input(player_id)
    Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 255 }, 1)
    if player_data.count_player_item(player_id, "F.Scrap") == 0 then
      player_data.update_player_item(player_id, "F.Scrap", 1)
    end

    Async.create_scope(function()
      Async.await(Async.sleep(1))

      player_data.hide_target_from_player(player_id, Net.get_player_area(player_id), context.bot_id, "ACTOR", true)

      Net.unlock_player_input(player_id)

      Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 0 }, 1)

      scripts:execute_next_node(context, context.area_id, node_object)
    end)
  end)

  scripts:implement_node("Open Hospital Gate", function(context, node_object)
    local player_id = context.player_id
    Net.lock_player_input(player_id)
    Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 255 }, 1)
    Async.await(Async.sleep(1))

    local area_id = Net.get_player_area(player_id)

    player_data.hide_target_from_player(player_id, area_id, context.bot_id, "ACTOR", true)

    Net.unlock_player_input(player_id)

    Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 0 }, 1)
  end)

  scripts:implement_node("Obtain Oven Coolant", function(context, node_object)
    local player_id = context.player_id
    local count = player_data.count_player_item(player_id, "Coolant")

    if count > 0 then player_data.update_player_item(player_id, "Coolant", -count) end

    player_data.update_player_item(player_id, "Coolant", 10)

    Net.message_player(player_id, "You got Coolant! Use it wisely!")

    local function revert_hidden(area_id)
      local objects_list = Net.list_objects(area_id)

      for _, object_id in ipairs(objects_list) do
        local target_object = Net.get_object_by_id(area_id, object_id)
        if target_object.type == "Checkpoint" and player_data.is_target_hidden(player_id, area_id, object_id, "OBJECT") == true then
          player_data.reveal_target_to_player(player_id, area_id, object_id, "OBJECT")
        end
      end
    end

    revert_hidden("Oven Network")
    revert_hidden("Oven Network 2")

    scripts:execute_next_node(context, context.area_id, node_object)
  end)

  scripts:implement_node("FiremanRV Battle", function(context, node_object)
    local player_id = context.player_id
    Net.initiate_encounter(player_id, "/server/assets/encounters/FiremanRV.zip", {})
    Net.exclude_actor_for_player(player_id, context.bot_id)
  end)

  scripts:implement_node("Buy Coffee", function(context, node_object)
    local player_id = context.player_id
    local player_mug = Net.get_player_mugshot(player_id)
    local player_texture = player_mug.texture_path
    local player_anim = player_mug.animation_path

    local mug_texture, mug_anim = scripts:resolve_mug(context, node_object)

    Async.create_scope(function()
      if Net.get_player_money(player_id) < 50 then
        Net.message_player(player_id, "We aren't running a charity here.", mug_texture, mug_anim)
      else
        Async.await(Async.message_player(player_id, "You hand over 50 Monies and get a hot cuppa joe."))

        player_data.update_player_money(player_id, -50)

        Net.play_sound_for_player(player_id, "/server/assets/NebuLibsAssets/sound effects/recover.ogg")

        local hp = Net.get_player_max_health(player_id)

        player_data.update_player_health(player_id, hp + math.floor(hp * 0.2))
        local message_list = {
          "Dark and bitter.\nYet, refreshing.\nJust like life?",
          "Disgustingly stale...\n\nIs this from last week...?",
          "Coffee made with apathy...Delicious!",
          "Did she put sugar in this?\n\nHah, that'd be the day!",
          "Who needs Dark Chips? I have this coffee!",
        }

        local flag_count = player_data.get_event_flag(player_id, "COFFEE_PURCHASE_COUNT", 0)

        player_data.set_event_flag(player_id, "COFFEE_PURCHASE_COUNT", flag_count + 1)

        Async.await(Async.message_player(player_id, message_list[math.random(#message_list)],
          player_texture, player_anim))
      end

      scripts:execute_next_node(context, context.area_id, node_object)
    end)
  end)

  scripts:implement_node("Buy Tea", function(context, node_object)
    local player_id = context.player_id
    local player_mug = Net.get_player_mugshot(player_id)
    local player_texture = player_mug.texture_path
    local player_anim = player_mug.animation_path

    local mug_texture, mug_anim = scripts:resolve_mug(context, node_object)

    Async.create_scope(function()
      if Net.get_player_money(player_id) < 50 then
        Net.message_player(player_id, "I'm sorry, but that's not enough cash~!", mug_texture,
          mug_anim)
      else
        Async.await(Async.message_player(player_id, "You hand over 50 Monies and get a calming cuppa tea."))

        player_data.update_player_money(player_id, -50)

        Net.play_sound_for_player(player_id, "/server/assets/NebuLibsAssets/sound effects/recover.ogg")

        local hp = Net.get_player_max_health(player_id)

        player_data.update_player_health(player_id, hp + math.floor(hp * 0.2))
        local message_list = {
          "*sip*.\n\n\nSo calming...!\nI needed this.",
          "Hot hot hot!\nMaybe I should let it cool next time...",
          "Tea made with genuine care...wonderful.",
          "There's honey in this! Is she sweet on me...?",
          "Not even a Secret Chip can measure up to the secret of her teamaking...!",
        }
        Async.await(Async.message_player(player_id, message_list[math.random(#message_list)],
          player_texture, player_anim))
      end

      scripts:execute_next_node(context, context.area_id, node_object)
    end)
  end)

  scripts:implement_node("Grant SirProof", function(context, node_object)
    local player_id = context.player_id
    local player_mug = Net.get_player_mugshot(player_id)
    local player_texture = player_mug.texture_path
    local player_anim = player_mug.animation_path

    local player_memory = player_data.get_player_data(player_id)

    local mug_texture, mug_anim = scripts:resolve_mug(context, node_object)

    Async.create_scope(function()
      if player_memory.event_data["SirProof"] == (nil or false) then
        if player_data.count_player_item(player_id, "CyberFrappe") > 0 then
          Net.message_player(player_id, "WHO DARES ENTER UNBIDDEN!?", mug_texture,
            mug_anim)
          Net.message_player(player_id, "...Uh-", player_texture,
            player_anim)
          Net.message_player(player_id,
            "YOU HAD BEST HAVE A GOOD REASON FOR THIS TRESPASS, PEON!", mug_texture, mug_anim)
          Net.message_player(player_id, "The gate opened because I have coffee...?",
            player_texture, player_anim)
          Net.message_player(player_id, "WAIT- YOU BROUGHT MY ORDER?", mug_texture,
            mug_anim)
          Net.message_player(player_id,
            "Some random navi told me to buy a coffee and said it might be useful.", player_texture,
            player_anim)
          Net.message_player(player_id, "SURLY, PUNKISH, CALLED YOU A LITTLE NAVI?",
            mug_texture, mug_anim)
          Net.message_player(player_id, "Yeah, sounds like him.", player_texture,
            player_anim)
          Net.message_player(player_id, "...Wait a minute. Did he send me to do his errands?",
            player_texture, player_anim)
          Net.message_player(player_id, "I DO NOT CARE. GIVE ME MY COFFEE! *GRAB*",
            mug_texture, mug_anim)
          Net.message_player(player_id, "Hey!", player_texture,
            player_anim)
          Net.message_player(player_id, "*GLUG* *GLUG*\nREFRESHING! IF A LITTLE COLD.",
            mug_texture, mug_anim)
          Net.message_player(player_id,
            "DELIVERIES HAVE BEEN EVER SO SLOW EVER SINCE NEBULA MOVED IN.", mug_texture,
            mug_anim)
          Async.await(Async.message_player(player_id, "Nebula, huh...", player_texture,
            player_anim))

          player_data.update_player_item(player_id, "CyberFrappe", -1)

          player_memory.event_data["LookACDC1"] = "SEEN"
          player_memory.event_data["SirProof"] = "SEEN"
          player_memory.event_data["Nebula1Battle"] = true
        end
      elseif player_memory.event_data["NebulaBattle1Finished"] == (nil or false) then
        Net.message_player(player_id, "WHO DARES- OH. IT'S YOU.", mug_texture,
          mug_anim)
        Net.message_player(player_id, "DELIVERIES HAVE BEEN EVER SO SLOW EVER SINCE NEBULA MOVED IN.", mug_texture,
          mug_anim)
        Net.message_player(player_id, "WON'T SOMEONE DO SOMETHING!?", mug_texture, mug_anim)
        Net.message_player(player_id, "HARUMPH!", mug_texture, mug_anim)
        Async.await(Async.message_player(player_id, "Nebula? Hmm...", player_texture,
          player_anim))
      elseif player_memory.event_data["SirProgReward"] == (nil or false) then
        Net.message_player(player_id, "WHO DARES- OH. IT'S YOU!", mug_texture,
          mug_anim)
        Net.message_player(player_id,
          "MY DELIVERIES HAVE BEEN COMING MUCH FASTER SINCE, I HEAR, *YOU* DEALT WITH THOSE NEBULA RUFFIANS.",
          mug_texture, mug_anim)
        Net.message_player(player_id, "A GENTLEMAN ALWAYS THANKS THOSE WHO HAVE AIDED HIM.", mug_texture, mug_anim)
        Async.await(Async.message_player(player_id, "TAKE THIS!", mug_texture, mug_anim))

        player_data.update_player_item(player_id, "HPMem", 1)

        Async.await(Async.message_player(player_id, "You got an HP Memory!"))
        player_data.save_player_data(player_id)
      else
        Async.await(Async.message_player(player_id, "THRASH NEBULA FOR ME! THE CADS DESERVE IT!",
          mug_texture, mug_anim))
      end

      scripts:execute_next_node(context, context.area_id, node_object)
    end)
  end)

  scripts:implement_node("Roll Dialogue", function(context, node_object)
    local player_id = context.player_id

    local player_mug = Net.get_player_mugshot(player_id)
    local player_texture = player_mug.texture_path
    local player_anim = player_mug.animation_path

    local mug_texture, mug_anim = scripts:resolve_mug(context, node_object)

    Net.message_player(player_id,
      "Hey there, " .. naviNames.player_navi_names[player_id] .. "! How's your day?", mug_texture,
      mug_anim)

    Async.create_scope(function()
      local result = Async.await(Async.quiz_player(player_id, "It's good", "It's bad", "Just OK",
        player_texture, player_anim))

      if result == 0 then
        Net.message_player(player_id, "It's pretty good, actually! I feel confident.",
          player_texture, player_anim)
        Async.await(Async.message_player(player_id, "That's great! I hope you keep having those days.",
          mug_texture, mug_anim))
      elseif result == 1 then
        Net.message_player(player_id, "It's pretty bad, honestly. Today has been pretty harsh.", player_texture,
          player_anim)
        Async.await(Async.message_player(player_id,
          "Oh...I'm sorry to hear that. I hope you feel better, " .. naviNames.player_navi_names[player_id] +
          ".", mug_texture, mug_anim))
      elseif result == 2 then
        Net.message_player(player_id, "It's going okay. Just...okay, really.", player_texture, player_anim)
        Async.await(Async.message_player(player_id, "Some days it's the small things that matter most.",
          mug_texture, mug_anim))
      end

      scripts:execute_next_node(context, context.area_id, node_object)
    end)
  end)

  scripts:implement_node("HP Memory Fan Dialogue", function(context, node_object)
    local player_id = context.player_id
    local mug_texture, mug_anim = scripts:resolve_mug(context, node_object)

    Async.create_scope(function()
      if player_data.count_player_item(player_id, "HPMem") == 0 then
        Async.await(Async.message_player(player_id, "DO YOU HAVE AN HP MEMORY? THERE'S ONE RIGHT THERE.",
          mug_texture, mug_anim))
      else
        Async.await(Async.message_player(player_id, "YAAAAY! YOU HAVE AN HP MEMORY!", mug_texture,
          mug_anim))
      end

      scripts:execute_next_node(context, context.area_id, node_object)
    end)
  end)

  scripts:implement_node("Copyman Plot", function(context, node_object)
    local player_id = context.player_id
    local player_memory = player_data.get_player_data(player_id)

    local mug_texture, mug_anim = scripts:resolve_mug(context, node_object)

    Async.create_scope(function()
      local player_mug = Net.get_player_mugshot(player_id)
      local player_texture = player_mug.texture_path
      local player_anim = player_mug.animation_path

      if player_memory.event_data["LookAround"] == true then
        Net.message_player(player_id, "Are you lost, little navi? This is the recycling bin.", mug_texture, mug_anim)
        Net.message_player(player_id, "I'm just looking around. Who are you?", player_texture, player_anim)
        Net.message_player(player_id, "Me? I'm nobody. Now, you though...", mug_texture, mug_anim)
        Net.message_player(player_id, "What about me?", player_texture, player_anim)
        Net.message_player(player_id, "You've got a glint in your eye...", mug_texture, mug_anim)
        Net.message_player(player_id, "Got big plans, do ya?", mug_texture, mug_anim)
        Net.message_player(player_id, "Don't say anything. Here, though, go on and get outta here with this.",
          mug_texture,
          mug_anim)
        Async.await(Async.message_player(player_id, "You got $150!"))

        player_data.update_player_money(player_id, 150)

        Async.await(Async.message_player(player_id, "Get a coffee or something on the way out. Could be useful.",
          mug_texture, mug_anim))
        player_memory.event_data["LookAround"] = "SEEN"
        player_memory.event_data["ACDC1"] = true
        player_data.save_player_data(player_id)
      elseif player_memory.event_data["ACDC1"] == true then
        Async.await(Async.message_player(player_id, "Go on, get out. That's all you're getting from me.",
          mug_texture, mug_anim))
      else
        Async.await(Async.message_player(player_id, "What?", mug_texture, mug_anim))
      end

      scripts:execute_next_node(context, context.area_id, node_object)
    end)
  end)
end
