local player_data = require('scripts/custom-scripts/player_data')

local ezshortcuts = require('scripts/custom-scripts/ezshortcuts')

local eventing_players = {}

Net:on("player_connect", function(event)
    local player_id = event.player_id
    local data = player_data.get_player_data(player_id)

    if data.joins > 1 then
        return
    end

    local textbox_options = {
        mug = Net.get_player_mugshot(player_id)
    }

    Net.hide_hud(player_id)
    Net.lock_player_input(player_id)
    Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 255 }, 0)

    Net.message_player(player_id, "What if the world were slightly different...?")
    Net.message_player(player_id, "What if, before the mighty Megaman and Lan took on Nebula...")
    Net.message_player(player_id, "Somebody else took center stage?")
    Net.message_player(player_id, "Well, I'm going to prove that they aren't the only heroes.", textbox_options)
    local promise = Async.message_player(player_id, "Come on! My story is just beginning!", textbox_options)

    promise.and_then(function()
        eventing_players[player_id] = true

        Net.transfer_player(player_id, "ACDC Square", false, 11.5, 12.5, 4, "Up Left")
        Net.unlock_player_input(player_id)
        Net.show_hud(player_id)
    end)
end)

Net:on("player_area_transfer", function(event)
    if not eventing_players[event.player_id] then
        return
    end

    eventing_players[event.player_id] = false

    local x, y, z = Net.get_player_position_multi(event.player_id)
    player_data.set_event_flag(event.player_id, "LOOK_AROUND", true)

    ezshortcuts.create_checkpoint(event.player_id, x, y, z, false)

    Net.fade_player_camera(event.player_id, { r = 0, g = 0, b = 0, a = 0 }, 1)
    Net.unlock_player_input(event.player_id)
end)

Net:on("player_disconnect", function(event)
    eventing_players[event.player_id] = false
end)
