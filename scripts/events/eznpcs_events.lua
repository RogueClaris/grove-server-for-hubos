local player_data = require('scripts/custom-scripts/player_data')
local LibPlugin = require('scripts/custom-custom/nebulous-liberations/main')
local naviNames = require('scripts/custom-scripts/navi_names')
local ezshortcuts = require('scripts/custom-scripts/ezshortcuts')

local CreateCheckpointEvent = {
	name = "Create Checkpoint",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		local pos = Net.get_player_position(player_id)
		ezshortcuts.create_checkpoint(player_id, pos.x, pos.y, pos.z, false)
	end)
}

local RematchProgEvent = {
	name = "Refight Liberation",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		return LibPlugin.start_game_for_player(player_id, dialogue.custom_properties["Liberation Map"])
	end)
}

local FightGutsmanEvent = {
	name = "Gutsman Battle",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		local results = Async.await(Async.initiate_encounter(player_id,
			"/server/assets/encounters/dependencies/com_Thor_Gutsman_V1.zip", {}))

		if not results.ran and results.health > 0 then
			player_data.update_player_item(player_id, "GutsProof", 1)

			local mug = get_dialogue_mugshot(npc, player_id, dialogue)
			local mug_texture = mug.texture_path;
			local mug_anim = mug.animation_path;

			local player_mug = get_dialogue_mugshot("player", player_id, dialogue)
			local player_texture = player_mug.texture_path;
			local player_anim = player_mug.animation_path;
			Net.message_player(player_id, "N-No way, guts!", mug_texture, mug_anim)
			Net.message_player(player_id, "Y-You're dead,\n" .. naviNames.player_navi_names[player_id] .. "!",
				mug_texture, mug_anim)
		end
	end)
}

local FightGutsmanV2Event = {
	name = "Gutsman V2 Battle",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		local results = Async.await(Async.initiate_encounter(player_id,
			"/server/assets/encounters/dependencies/com_Thor_Gutsman_V2.zip", {}))
		if not results.ran and results.health > 0 then
			player_data.update_player_item(player_id, "GutsProof", 1)

			local mug = get_dialogue_mugshot(npc, player_id, dialogue)
			local mug_texture = mug.texture_path;
			local mug_anim = mug.animation_path;

			local player_mug = Net.get_player_mugshot(player_id)
			local player_texture = player_mug.texture_path;
			local player_anim = player_mug.animation_path;
			Net.message_player(player_id, "S-So shameful, guts...!", mug_texture, mug_anim)
			Net.message_player(player_id, "H-How are you\nso strong,\n" ..
				naviNames.player_navi_names[player_id] .. "!?", mug_texture, mug_anim)
		end
	end)
}

local FightGutsmanV3Event = {
	name = "Gutsman V3 Battle",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		local results = Async.await(Async.initiate_encounter(player_id,
			"/server/assets/encounters/dependencies/com_Thor_Gutsman_V3.zip", {}))
		if not results.ran and results.health > 0 then
			player_data.update_player_item(player_id, "GutsProof", 1)

			local mug = get_dialogue_mugshot(npc, player_id, dialogue)
			local mug_texture = mug.texture_path;
			local mug_anim = mug.animation_path;

			local player_mug = Net.get_player_mugshot(player_id)
			local player_texture = player_mug.texture_path;
			local player_anim = player_mug.animation_path;
			Net.message_player(player_id, "I-I'll get you next time, guts!", mug_texture, mug_anim)
		end
	end)
}

local FightGutsmanV4Event = {
	name = "Gutsman V4 Battle",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		local item = {
			name = "GutsHamr",
			description = "A hammer that takes guts to wield. Use it in Liberations!",
			consumable = false
		}

		local results = Async.await(Async.initiate_encounter(player_id,
			"/server/assets/encounters/dependencies/com_Thor_Gutsman_V4.zip", {}))
		if results and not results.ran and results.health > 0 then
			player_data.update_player_item(player_id, "GutsProof", 1)

			local mug = get_dialogue_mugshot(npc, player_id, dialogue)
			local mug_texture = mug.texture_path;
			local mug_anim = mug.animation_path;

			Net.message_player(player_id, "...\n\n\nYou really get me, guts! Take this.", mug_texture, mug_anim)
			Net.message_player(player_id, "You got Guts Hammer! Use it in liberations.")

			local count = player_data.count_player_item(player_id, "GutsHamr")

			if count > 0 then return end

			player_data.update_player_item(player_id, "GutsHamr", 1)
		end
	end)
}

local RemoveBass1 = {
	name = "Remove Bass ACDC 4",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		Net.lock_player_input(player_id)
		Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 255 }, 1)
		if player_data.count_player_item(player_id, "F.Scrap") == 0 then
			player_data.update_player_item(player_id, F.Scrap, 1)
		end

		Async.await(Async.sleep(1))

		player_data.hide_target_from_player(player_id, Net.get_player_area(player_id), npc.bot_id, "ACTOR", true)

		Net.unlock_player_input(player_id)

		Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 0 }, 1)
	end)
}

local GetYaiCode = {
	name = "Get Yai Code",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		Net.lock_player_input(player_id)
		Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 255 }, 1)
		local item = {
			name = "YaiCode",
			description = "The PCode to Yai's HP. A lady always repays her debts!",
			consumable = false
		}

		if player_data.count_player_item(player_id, "YaiCode") == 0 then
			player_data.update_player_item(player_id, "YaiCode", 1)
		end

		Async.await(Async.sleep(1))

		player_data.hide_target_from_player(player_id, Net.get_player_area(player_id), npc.bot_id, "ACTOR", true)

		Net.unlock_player_input(player_id)
		Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 0 }, 1)
	end)
}

local GetYaiData = {
	name = "Get Yai Data",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		Net.lock_player_input(player_id)
		Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 255 }, 1)

		if player_data.count_player_item(player_id, "YaiData") == 0 then
			player_data.update_player_item(player_id, "YaiData", 1)
		end

		Async.await(Async.sleep(1))

		player_data.hide_target_from_player(player_id, Net.get_player_area(player_id), npc.bot_id, "ACTOR", true)

		Net.unlock_player_input(player_id)
		Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 0 }, 1)
	end)
}

local GlydeProgQuestTrigger = {
	name = "GlydeProgQuest",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		local player_memory = player_data.get_player_data(player_id)
		local subquests = player_memory.subquest_flags

		if subquests == nil then subquests = {} end

		if subquests["YaiHomework"] == nil then
			subquests["YaiHomework"] = {
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
		end

		if subquests["YaiHomework"].completed == true then return end

		if subquest["YaiHomework"].started == false then
			subquest["YaiHomework"].started = true
		end
	end)
}

local OpenHospGate = {
	name = "Open Hospital Gate",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		Net.lock_player_input(player_id)
		Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 255 }, 1)
		Async.await(Async.sleep(1))

		local area_id = Net.get_player_area(player_id)

		player_data.hide_target_from_player(player_id, area_id, npc.bot_id, "ACTOR", true)

		Net.unlock_player_input(player_id)

		Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 0 }, 1)
	end)
}

local PlaydomePlaytime = {
	name = "Playdome Playtime",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		local area_id = Net.get_player_area(player_id)
		local object = Net.get_object_by_name(area_id, "Playdome")
		Net.lock_player_input(player_id)
		Net.move_player_camera(player_id, object.x, object.y, object.z, 5)
		Net.exclude_actor_for_player(player_id, player_id)
		Async.await(Async.sleep(5))
		Net.unlock_player_camera(player_id)
		Net.include_actor_for_player(player_id, player_id)
		Net.unlock_player_input(player_id)
	end)
}

local GetOvenCoolant = {
	name = "Obtain Oven Coolant",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
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
	end)
}

local FightFiremanRV = {
	name = "FiremanRV Battle",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		Net.initiate_encounter(player_id, "/server/assets/encounters/FiremanRV.zip", {})
		return Net.exclude_actor_for_player(player_id, npc.bot_id)
	end)
}

local GrantLiberationAbility = {
	name = "Grant Liberation Mission Ability",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		if dialogue.custom_properties["Ability Item"] ~= nil then
			player_data.update_player_item(player_id, dialogue.custom_properties["Ability Item"], 1)
		end
	end)
}

local GiveCoffeeEvent = {
	name = "Buy Coffee",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		local mug = get_dialogue_mugshot(npc, player_id, dialogue)
		local mug_texture = mug.texture_path;
		local mug_anim = mug.animation_path;

		local player_mug = Net.get_player_mugshot(player_id)
		local player_texture = player_mug.texture_path;
		local player_anim = player_mug.animation_path;
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
	end)
}

local GiveTeaEvent = {
	name = "Buy Tea",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		local mug = get_dialogue_mugshot(npc, player_id, dialogue)
		local mug_texture = mug.texture_path;
		local mug_anim = mug.animation_path;

		local player_mug = Net.get_player_mugshot(player_id)
		local player_texture = player_mug.texture_path;
		local player_anim = player_mug.animation_path;
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
	end)
}

local VirologistDateCheck = {
	name = "Virologist Timer Check",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		--Get the player memory
		local player_memory = player_data.get_player_data(player_id)
		--If the specified player doesn't have quest data in their memory, initialize it.
		if not player_memory.quest_data then player_memory.quest_data = {} end
		--Get the NPC mugshot for message use.
		local mug = get_dialogue_mugshot(npc, player_id, dialogue)
		--If the player memory has a virologist date saved (custom data from me), and the current time is less than that date, tell the player to return later.
		if player_memory.quest_data["ACDC2Virologist"] and os.time() < player_memory.quest_data["ACDC2Virologist"] then
			Async.await(Async.message_player(player_id, "I'm sorry, I'm still studying the data.", mug_texture,
				mug_anim))
			Async.await(Async.message_player(player_id, "Please come back later.", mug_texture,
				mug_anim))
			--Don't proceed. We're too early to try this quest again.
			return nil
		end
		return dialogue.custom_properties["Next 1"]
	end)
}

local VirologistAssistance = {
	name = "Virologist Battle",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		--Get the player memory
		local player_memory = player_data.get_player_data(player_id)
		--If the specified player doesn't have quest data in their memory, initialize it.
		if not player_memory.quest_data then player_memory.quest_data = {} end

		--Get the NPC mugshot for message use.
		local mug = get_dialogue_mugshot(npc, player_id, dialogue)

		local mhp = player_data.get_player_max_health(player_id)

		--Initiate an encounter.
		local results = Async.await(Async.initiate_encounter(player_id,
			"/server/assets/encounters/VirologistData.zip", {}))
		--If we won and didn't run, let's begin processing our reward!
		if not results.ran then
			--Default timer is 24 hours later. Save the date!
			local new_date = os.time()
			if results.health > 0 then
				new_date = new_date + ((60 * 60) * 24)

				--Set our emotion...
				if results.emotion == 1 then
					Net.set_player_emotion(player_id, results.emotion)
				else
					Net.set_player_emotion(player_id, 0)
				end
				--Set our health...
				Net.set_player_health(player_id, results.health)
				Net.lock_player_input(player_id)
				Async.await(Async.message_player(player_id, "Most informative! Thank you.", mug_texture,
					mug_anim))
				--Virologist heals us.
				Async.await(Async.message_player(player_id, "Allow me to restore your health.", mug_texture,
					mug_anim))
				--Heal to max

				player_data.update_player_health(player_id, mhp)
				--Provide a recover SFX from the server so that we guarantee it exists.

				Net.play_sound_for_player(player_id, "/server/assets/NebuLibsAssets/sound effects/recover.ogg")

				--Give the player 500 Monies!
				Async.await(Async.message_player(player_id, "Please, take this for your trouble.", mug_texture,
					mug_anim))

				Async.await(Async.message_player(player_id, "Got $500!"))

				--Spend in reverse to gain.
				player_data.update_player_money(player_id, 500)

				--Tell the player what the Virologist is up to for the next while, and when to come back.
				Async.await(Async.message_player(player_id, "I need to study this data...", mug_texture,
					mug_anim))
				Async.await(Async.message_player(player_id, "Could you give me 24 hours?", mug_texture,
					mug_anim))
				Net.unlock_player_input(player_id)
			else
				--Retry date is an hour later.
				new_date = new_date + (60 * 60)
				Net.lock_player_input(player_id)
				--We're Worried now.
				Net.set_player_emotion(player_id, 5)
				--Health is 1 because we lost during an event.
				Net.set_player_health(player_id, 1)
				--Virologist is upset. Swears based on Battle Network terms.
				Async.await(Async.message_player(player_id, "Bust it all, that was too close!", mug_texture,
					mug_anim))
				--Virologist heals us.
				Async.await(Async.message_player(player_id, "I'm sorry. Let me fix you up.", mug_texture,
					mug_anim))
				--Heal to max

				player_data.update_player_health(player_id, mhp)
				--Provide a recover SFX from the server so that we guarantee it exists.
				Net.play_sound_for_player(player_id, "/server/assets/NebuLibsAssets/sound effects/recover.ogg")
				Async.await(Async.message_player(player_id, "I'll log this incident right away.", mug_texture,
					mug_anim))
				Async.await(Async.message_player(player_id,
					"Come back in an hour if you're still willing to help me with my research.", mug_texture,
					mug_anim))
				Net.unlock_player_input(player_id)
			end
			--Set reattempt timer.
			player_memory.quest_data["ACDC2Virologist"] = new_date
			--Save the player memory so they can attempt later.
			player_data.save_player_data(player_id)
		end
	end)
}

local GiveSirProof = {
	name = "Grant SirProof",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		local mug = get_dialogue_mugshot(npc, player_id, dialogue)
		local mug_texture = mug.texture_path;
		local mug_anim = mug.animation_path;

		local player_mug = Net.get_player_mugshot(player_id)
		local player_texture = player_mug.texture_path;
		local player_anim = player_mug.animation_path;



		local player_memory = player_data.get_player_data(player_id)

		if player_memory.event_data["SirProof"] == (nil or false) then
			if player_data.count_player_item(player_id, "CyberFrappe") > 0 then
				Async.await(Async.message_player(player_id, "WHO DARES ENTER UNBIDDEN!?", mug_texture,
					mug_anim))
				Async.await(Async.message_player(player_id, "...Uh-", player_texture,
					player_anim))
				Async.await(Async.message_player(player_id,
					"YOU HAD BEST HAVE A GOOD REASON FOR THIS TRESPASS, PEON!", mug_texture, mug_anim))
				Async.await(Async.message_player(player_id, "The gate opened because I have coffee...?",
					player_texture, player_anim))
				Async.await(Async.message_player(player_id, "WAIT- YOU BROUGHT MY ORDER?", mug_texture,
					mug_anim))
				Async.await(Async.message_player(player_id,
					"Some random navi told me to buy a coffee and said it might be useful.", player_texture,
					player_anim))
				Async.await(Async.message_player(player_id, "SURLY, PUNKISH, CALLED YOU A LITTLE NAVI?",
					mug_texture, mug_anim))
				Async.await(Async.message_player(player_id, "Yeah, sounds like him.", player_texture,
					player_anim))
				Async.await(Async.message_player(player_id, "...Wait a minute. Did he send me to do his errands?",
					player_texture, player_anim))
				Async.await(Async.message_player(player_id, "I DO NOT CARE. GIVE ME MY COFFEE! *GRAB*",
					mug_texture, mug_anim))
				Async.await(Async.message_player(player_id, "Hey!", player_texture,
					player_anim))
				Async.await(Async.message_player(player_id, "*GLUG* *GLUG*\nREFRESHING! IF A LITTLE COLD.",
					mug_texture, mug_anim))
				Async.await(Async.message_player(player_id,
					"DELIVERIES HAVE BEEN EVER SO SLOW EVER SINCE NEBULA MOVED IN.", mug_texture,
					mug_anim))
				Async.await(Async.message_player(player_id, "Nebula, huh...", player_texture,
					player_anim))

				player_data.update_player_item(player_id, "CyberFrappe", -1)

				player_memory.event_data["LookACDC1"] = "SEEN"
				player_memory.event_data["SirProof"] = "SEEN"
				player_memory.event_data["Nebula1Battle"] = true
			end
		else
			if player_memory.event_data["NebulaBattle1Finished"] == (nil or false) then
				Async.await(Async.message_player(player_id, "WHO DARES- OH. IT'S YOU.", mug_texture,
					mug_anim))
				Async.await(Async.message_player(player_id,
					"DELIVERIES HAVE BEEN EVER SO SLOW EVER SINCE NEBULA MOVED IN.", mug_texture,
					mug_anim))
				Async.await(Async.message_player(player_id, "WON'T SOMEONE DO SOMETHING!?", mug_texture,
					mug_anim))
				Async.await(Async.message_player(player_id, "HARUMPH!", mug_texture, mug_anim))
				Async.await(Async.message_player(player_id, "Nebula? Hmm...", player_texture,
					player_anim))
			else
				if player_memory.event_data["SirProgReward"] == (nil or false) then
					Async.await(Async.message_player(player_id, "WHO DARES- OH. IT'S YOU!", mug_texture,
						mug_anim))
					Async.await(Async.message_player(player_id,
						"MY DELIVERIES HAVE BEEN COMING MUCH FASTER SINCE, I HEAR, *YOU* DEALT WITH THOSE NEBULA RUFFIANS.",
						mug_texture, mug_anim))
					Async.await(Async.message_player(player_id, "A GENTLEMAN ALWAYS THANKS THOSE WHO HAVE AIDED HIM.",
						mug_texture, mug_anim))
					Async.await(Async.message_player(player_id, "TAKE THIS!", mug_texture, mug_anim))

					player_data.update_player_item(player_id, "HPMem", 1)

					Async.await(Async.message_player(player_id, "You got an HP Memory!"))
					player_data.save_player_data(player_id)
				else
					Async.await(Async.message_player(player_id, "THRASH NEBULA FOR ME! THE CADS DESERVE IT!",
						mug_texture, mug_anim))
				end
			end
		end
	end)
}

local CyberRailWarp = {
	name = "Conductor Teleport",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		local area_id = dialogue.custom_properties["Warp Map"]
		local object = Net.get_object_by_name(area_id, "Conductor Warp")
		local direction = object.custom_properties["Direction"] or Net.get_player_direction(player_id)
		Net.transfer_player(player_id, area_id, true, object.x, object.y, object.z, direction)
	end)
}

local GiveRailPassPls = {
	name = "Give RailPass",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		local player_memory = player_data.get_player_data(player_id)
		local mug = get_dialogue_mugshot(npc, player_id, dialogue)
		local mug_texture = mug.texture_path;
		local mug_anim = mug.animation_path;

		Net.lock_player_input(player_id)
		Async.await(Async.message_player(player_id, "HELLO!", mug_texture, mug_anim))
		if player_memory.event_data["NebulaBattle1Finished"] ~= true then
			Async.await(Async.message_player(player_id, "WE ARE CURRENTLY EXPERIENCING SERVICE INTERRUPTIONS.",
				mug_texture, mug_anim))
			Async.await(Async.message_player(player_id, "PLEASE CHECK BACK LATER!", mug_texture,
				mug_anim))
		else
			Async.await(Async.message_player(player_id, "WE ARE ONCE AGAIN OPEN FOR BUSINESS!", mug_texture,
				mug_anim))
			Async.await(Async.message_player(player_id, "SORRY ABOUT THAT.", mug_texture, mug_anim))
			Async.await(Async.message_player(player_id,
				"SOME HOOLIGANS WERE BLOCKING THE RAILS! IT'S CLEARED UP NOW.", mug_texture, mug_anim))
			Async.await(Async.message_player(player_id,
				"INSTEAD OF RELYING ON THOSE OLD TRAMS, WE NOW OFFER A TELEPORT SERVICE!", mug_texture,
				mug_anim))
			Async.await(Async.message_player(player_id, "HERE'S YOUR COMMEMORATIVE RAIL PASS!", mug_texture,
				mug_anim))

			player_data.update_player_item(player_id, "RailPass", 1)
		end
		Net.unlock_player_input(player_id)
	end)
}

local RollDialogue = {
	name = "Roll Dialogue",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		local mug = get_dialogue_mugshot(npc, player_id, dialogue)
		local mug_texture = mug.texture_path;
		local mug_anim = mug.animation_path;

		local player_mug = Net.get_player_mugshot(player_id)
		local player_texture = player_mug.texture_path;
		local player_anim = player_mug.animation_path;
		Async.await(Async.message_player(player_id,
			"Hey there, " .. naviNames.player_navi_names[player_id] .. "! How's your day?", mug_texture,
			mug_anim))
		local result = Async.await(Async.quiz_player(player_id, "It's good", "It's bad", "Just OK",
			player_texture, player_anim))
		if result == 0 then
			Async.await(Async.message_player(player_id, "It's pretty good, actually! I feel confident.",
				player_texture, player_anim))
			Async.await(Async.message_player(player_id, "That's great! I hope you keep having those days.",
				mug_texture, mug_anim))
		elseif result == 1 then
			Async.await(Async.message_player(player_id, "It's pretty bad, honestly. Today has been pretty harsh.",
				player_texture, player_anim))
			Async.await(Async.message_player(player_id,
				"Oh...I'm sorry to hear that. I hope you feel better, " .. naviNames.player_navi_names[player_id] +
				".", mug_texture, mug_anim))
		elseif result == 2 then
			Async.await(Async.message_player(player_id, "It's going okay. Just...okay, really.",
				player_texture, player_anim))
			Async.await(Async.message_player(player_id, "Some days it's the small things that matter most.",
				mug_texture, mug_anim))
		end
	end)
}

local HPMemFanDialogue = {
	name = "HP Memory Fan Dialogue",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		local mug = get_dialogue_mugshot(npc, player_id, dialogue)
		local mug_texture = mug.texture_path;
		local mug_anim = mug.animation_path;

		local player_mug = Net.get_player_mugshot(player_id)
		local player_texture = player_mug.texture_path;
		local player_anim = player_mug.animation_path;
		if player_data.count_player_item(player_id, "HPMem") == 0 then
			Async.await(Async.message_player(player_id, "DO YOU HAVE AN HP MEMORY? THERE'S ONE RIGHT THERE.",
				mug_texture, mug_anim))
		else
			Async.await(Async.message_player(player_id, "YAAAAY! YOU HAVE AN HP MEMORY!", mug_texture,
				mug_anim))
		end
	end)
}

local CopymanDialogue = {
	name = "Copyman Plot",
	action = Async.create_function(function(npc, player_id, dialogue, relay_object)
		local player_memory = player_data.get_player_data(player_id)
		local mug = get_dialogue_mugshot(npc, player_id, dialogue)
		local mug_texture = mug.texture_path;
		local mug_anim = mug.animation_path;

		local player_mug = Net.get_player_mugshot(player_id)
		local player_texture = player_mug.texture_path;
		local player_anim = player_mug.animation_path;
		if player_memory.event_data["LookAround"] == true then
			Async.await(Async.message_player(player_id, "Are you lost, little navi? This is the recycling bin.",
				mug_texture, mug_anim))
			Async.await(Async.message_player(player_id, "I'm just looking around. Who are you?",
				player_texture, player_anim))
			Async.await(Async.message_player(player_id, "Me? I'm nobody. Now, you though...", mug_texture,
				mug_anim))
			Async.await(Async.message_player(player_id, "What about me?", player_texture,
				player_anim))
			Async.await(Async.message_player(player_id, "You've got a glint in your eye...", mug_texture,
				mug_anim))
			Async.await(Async.message_player(player_id, "Got big plans, do ya?", mug_texture, mug
				.animation_path))
			Async.await(Async.message_player(player_id,
				"Don't say anything. Here, though, go on and get outta here with this.", mug_texture,
				mug_anim))
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
	end)
}
