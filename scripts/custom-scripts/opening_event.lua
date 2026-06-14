local player_data = require('scripts/custom-scripts/player_data')

local ezshortcuts = require('scripts/custom-scripts/ezshortcuts')

local eventing_players = {}

local instance_manager = require("scripts/libs/instancer")

Net:on("player_connect", function(event)
    local player_id = event.player_id
    local data = player_data.get_player_data(player_id)

    if data.joins > 1 then
        return
    end

    Net.hide_hud(player_id)

    Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 255 }, 0)

    local instancer = instance_manager:new()
    local instance_id = instancer:create_instance()
    local area_id = instancer:clone_area_to_instance(instance_id, "default") --[[@as string]]

    Net.transfer_player(player_id, area_id, false)

    Net.fade_player_camera(player_id, { r = 0, g = 0, b = 0, a = 255 }, 0)

    local title_sprite = Net.create_sprite({
        player_id = player_id,
        parent_id = "hud",
        texture_path = "/server/assets/title_gaiden.png",
        animation_path = "/server/assets/title_gaiden.animation",
        animation = "DEFAULT",
        layer = -10,
    })

    Net.animate_sprite(title_sprite, "DEFAULT")

    local start_sprite = Net.create_sprite({
        player_id = player_id,
        parent_id = "hud",
        x = 120,
        y = 140,
        texture_path = "/server/assets/press_start.png",
        animation_path = "/server/assets/press_start.animation",
        animation = "DEFAULT",
        layer = -20
    })

    Net.animate_sprite(start_sprite, "DEFAULT")

    eventing_players[player_id] = { eventing = true, title = title_sprite, start = start_sprite }
end)

Net:on("tile_interaction", function(event)
    if not eventing_players[event.player_id] then return end
    if eventing_players[event.player_id].eventing == false then return end
    if event.button ~= 0 then return end

    Net.play_sound_for_player(event.player_id, "/server/assets/sfx/press_start.ogg")

    Net.fade_player_camera(event.player_id, { r = 0, g = 0, b = 0, a = 255 }, 0.25)

    Async.create_scope(function()
        Net.remove_sprite(eventing_players[event.player_id].title)
        Net.remove_sprite(eventing_players[event.player_id].start)

        Async.await(Async.sleep(0.25))

        eventing_players[event.player_id].title = nil
        eventing_players[event.player_id].start = nil

        Net.transfer_player(event.player_id, "ACDC Square", false, 11.5, 12.5, 4, "Up Left")
    end)
end)

Net:on("player_area_transfer", function(event)
    if not eventing_players[event.player_id] then return end
    if player_data.get_join_count(event.player_id) > 1 then return end
    if eventing_players[event.player_id].start ~= nil or eventing_players[event.player_id].title ~= nil then return end

    eventing_players[event.player_id].eventing = false

    local x, y, z = Net.get_player_position_multi(event.player_id)
    player_data.set_event_flag(event.player_id, "LOOK_AROUND", true)

    ezshortcuts.create_checkpoint(event.player_id, x, y, z, false)

    Net.fade_player_camera(event.player_id, { r = 0, g = 0, b = 0, a = 0 }, 0.25)
end)

Net:on("player_disconnect", function(event)
    eventing_players[event.player_id] = false
end)
