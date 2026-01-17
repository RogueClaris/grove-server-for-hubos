local player_data = require('scripts/custom-scripts/player_data')

local plugin = {}

plugin.flags_map = {
    LookAround = "I should look around before leaving...",
    ACDC1 = "I should head to ACDC 1.",
    LookACDC1 = "I should ask around in case anyone needs help!",
    Nebula1Battle = "Nebula is occupying ACDC Area!\nSomeone has to do something...!",
    Nebula1BattleFinished = "I wonder what I should do next..."
}

local function handle_help_text(button, player_id)
    if button ~= 1 or string.match(Net.get_area_name(Net.get_player_area(player_id)), "Nebula") then return end

    local player_memory = player_data.get_player_data(player_id)

    if player_memory.event_data == nil then return end;

    local mug = Net.get_player_mugshot(player_id)
    local pos = Net.get_player_position(player_id)
    local dialogue = nil
    for k, v in pairs(plugin.flags_map) do
        if player_memory.event_data[k] == true then
            dialogue = v
            break
        end
    end
    if dialogue ~= nil then
        Net.teleport_player(player_id, false, pos.x, pos.y, pos.z, "Down")
        Net.message_player(player_id, dialogue, mug.texture_path, mug.animation_path)
    end
end

Net:on("tile_interaction", function(event)
    local button = event.button
    local player_id = event.player_id
    handle_help_text(button, player_id)
end)

Net:on("actor_interaction", function(event)
    local button = event.button
    local player_id = event.player_id
    handle_help_text(button, player_id)
end)

Net:on("player_area_transfer", function(event)
    local player_id = event.player_id
    local area_id = Net.get_player_area(player_id)
    local name = Net.get_area_name(area_id)

    local player_memory = player_data.get_player_data(player_id)
    if name == "ACDC 1" and player_memory.event_data["ACDC1"] then
        player_memory.event_data["ACDC1"] = "SEEN"
        player_memory.event_data["LookACDC1"] = true
    end
end)

return plugin
