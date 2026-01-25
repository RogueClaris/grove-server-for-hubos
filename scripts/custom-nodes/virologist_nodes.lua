local player_data = require('scripts/custom-scripts/player_data')

---@param scripts ScriptNodes
return function(scripts)
  scripts:implement_node("Virologist Timer Check", function(context, node_object)
    local player_id = context.player_id
    --Get the player memory
    local player_memory = player_data.get_player_data(player_id)
    --If the specified player doesn't have quest data in their memory, initialize it.
    if not player_memory.quest_data then player_memory.quest_data = {} end

    --If the player memory has a virologist date saved (custom data from me), and the current time is less than that date, tell the player to return later.
    if player_memory.quest_data["ACDC2Virologist"] and os.time() < player_memory.quest_data["ACDC2Virologist"] then
      local mug_texture, mug_anim = scripts:resolve_mug(context, node_object)
      Net.message_player(player_id, "I'm sorry, I'm still studying the data.", mug_texture, mug_anim)
      Net.message_player(player_id, "Please come back later.", mug_texture, mug_anim)
      --Don't proceed. We're too early to try this quest again.
      return
    end

    scripts:execute_next_node(context, context.area_id, node_object)
  end)

  scripts:implement_node("Virologist Battle", function(context, node_object)
    local player_id = context.player_id

    --Get the player memory
    local player_memory = player_data.get_player_data(player_id)
    --If the specified player doesn't have quest data in their memory, initialize it.
    if not player_memory.quest_data then player_memory.quest_data = {} end

    Async.create_scope(function()
      local mhp = player_data.get_player_max_health(player_id)

      --Initiate an encounter.
      local results = Async.await(Async.initiate_encounter(player_id, "/server/assets/encounters/VirologistData.zip", {}))

      --If we won and didn't run, let's begin processing our reward!
      if not results.ran then
        scripts:execute_next_node(context, context.area_id, node_object)
        return
      end

      local mug_texture, mug_anim = scripts:resolve_mug(context, node_object)

      --Default timer is 24 hours later. Save the date!
      local new_date = os.time()
      if results.health > 0 then
        new_date = new_date + ((60 * 60) * 24)

        --Set our emotion...
        if results.emotion == 1 then
          Net.set_player_emotion(player_id, results.emotion)
        else
          Net.set_player_emotion(player_id, "DEFAULT")
        end
        --Set our health...
        Net.set_player_health(player_id, results.health)
        Net.lock_player_input(player_id)
        Net.message_player(player_id, "Most informative! Thank you.", mug_texture, mug_anim)
        --Virologist heals us.
        Async.await(Async.message_player(player_id, "Allow me to restore your health.", mug_texture,
          mug_anim))

        Net.synchronize(function()
          --Heal to max
          player_data.update_player_health(player_id, mhp)
          --Provide a recover SFX from the server so that we guarantee it exists.
          Net.play_sound_for_player(player_id, "/server/assets/liberations/sound effects/recover.ogg")
        end)

        --Give the player 500 Monies!
        Net.message_player(player_id, "Please, take this for your trouble.", mug_texture, mug_anim)
        Async.await(Async.message_player(player_id, "Got $500!"))

        --Spend in reverse to gain.
        player_data.update_player_money(player_id, 500)

        --Tell the player what the Virologist is up to for the next while, and when to come back.
        Net.message_player(player_id, "I need to study this data...", mug_texture, mug_anim)
        Async.await(Async.message_player(player_id, "Could you give me 24 hours?", mug_texture,
          mug_anim))
        Net.unlock_player_input(player_id)
      else
        --Retry date is an hour later.
        new_date = new_date + (60 * 60)
        Net.lock_player_input(player_id)
        --We're Worried now.
        Net.set_player_emotion(player_id, "ANXIOUS")
        --Health is 1 because we lost during an event.
        Net.set_player_health(player_id, 1)
        --Virologist is upset. Swears based on Battle Network terms.
        Net.message_player(player_id, "Bust it all, that was too close!", mug_texture, mug_anim)
        --Virologist heals us.
        Async.await(Async.message_player(player_id, "I'm sorry. Let me fix you up.", mug_texture,
          mug_anim))
        --Heal to max

        player_data.update_player_health(player_id, mhp)
        --Provide a recover SFX from the server so that we guarantee it exists.
        Net.play_sound_for_player(player_id, "/server/assets/liberations/sound effects/recover.ogg")
        Net.message_player(player_id, "I'll log this incident right away.", mug_texture, mug_anim)
        Async.await(Async.message_player(player_id,
          "Come back in an hour if you're still willing to help me with my research.", mug_texture,
          mug_anim))
        Net.unlock_player_input(player_id)
      end

      --Set reattempt timer.
      player_memory.quest_data["ACDC2Virologist"] = new_date
      --Save the player memory so they can attempt later.
      player_data.save_player_data(player_id)

      scripts:execute_next_node(context, context.area_id, node_object, 2)
    end)
  end)
end
