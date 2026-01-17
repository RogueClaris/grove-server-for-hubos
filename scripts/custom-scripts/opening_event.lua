local player_data = require('scripts/custom-scripts/player_data')

local ezshortcuts = require('scripts/custom-scripts/ezshortcuts')

local eventing_players = {}

Net:on("player_connect", function(event)
    local player_id = event.player_id

    local data = player_data.get_player_data(player_id)
    local mug = Net.get_player_mugshot(player_id)

    if data.joins <= 1 and not Net.is_player_busy(player_id) then
        player_data.set_event_flag(player_id, "SEEN", true)

        eventing_players[player_id] = true

        Net.hide_hud(player_id)
        Net.lock_player_input(player_id)
        Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 255 }, 0)

        Net.message_player(player_id, "What if the world were slightly different...?")
        Net.message_player(player_id, "What if, before the mighty Megaman and Lan took on Nebula...")
        Net.message_player(player_id, "Somebody else took center stage?")
        Net.message_player(player_id, "Well, I'm going to prove that they aren't the only heroes.", mug.texture_path,
            mug.animation_path)
        Net.message_player(player_id, "Come on! My story is just beginning!", mug.texture_path, mug.animation_path)
    end
end)

Net:on("textbox_response", function(event)
    local k = event.player_id
    if eventing_players[event.player_id] == true and not Net.is_player_in_widget(k) then
        player_data.set_event_flag(k, "SEEN", true)
        Net.transfer_player(k, "ACDC Square", false, 11.5, 12.5, 4, "Up Left")
        Net.unlock_player_input(k)
        Net.show_hud(k)
    end
end)

Net:on("player_area_transfer", function(event)
    if player_data.get_event_flag(event.player_id, "SEEN", false) == true then
        local pos = Net.get_player_position(event.player_id)
        player_data.set_event_flag(event.player_id, "LOOK_AROUND", true)

        ezshortcuts.create_checkpoint(event.player_id, pos.x, pos.y, pos.z, false)

        eventing_players[event.player_id] = false

        Net.fade_player_camera(event.player_id, { r = 0, g = 0, b = 0, a = 0 }, 1)
        Net.unlock_player_input(event.player_id)
    end
end)
