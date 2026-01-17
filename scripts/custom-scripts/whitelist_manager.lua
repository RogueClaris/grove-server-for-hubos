local player_data = require('scripts/custom-scripts/player_data')

local plugin = {}

-- plugin.enemy_rank_reward_table = {
--     Canodumb = {
--         { 4, "5476146df06d1283b68e0eefb8212e76 com.claris.card.Cannon1", "Cannon" }
--     },
--     Mettaur = {
--         { 8, "dc0cd149581b2a6552ed7f2ba8ba39af com.k1rbyat1na.card.EXE6-091-ReflecMet1", "Reflector 1" },
--         { 4, "bef75ce17b34759bab7606157ebb837d rune.onb.ShockWav",                       "Shock Wave" },
--     },
--     Fishy = {
--         { 7, "54e71a98a2a41862820999e9661052d1 com.louise.card.dashattck", "Dash Attack" }
--     },
--     Ratty = {
--         { 6, "7270ddf16e016bdd58816c60ab6534a8 Ratton1.rune.legacy", "Ratton 1" }
--     },
--     Ratty2 = {
--         { 6, "ab4e4f2a567af456a0fb5d80339cb098 rune.legacy.ratton2", "Ratton 2" }
--     },
--     Shrimpy = {
--         { 6, "30e091d976b25642482380a7c432682d rune.legacy.bubbler", "Bubbler" }
--     },
--     Piranha = {
--         { 5, "48625768ce8ef5f65f418e1eefed2553 com.louise.card.trainarrow1", "Train Arrow 1" }
--     },
--     Quaker = {
--         { 7, "207bf66cdb8a58412ed278a2bd2e6641 IceWave.PVP", "Ice Wave" }
--     },
--     Volgear = {
--         { 6, "d8e8f0bad2387ed840719cd88e49d60e hoov.card.flameline1", "Flame Line 1" }
--     },
--     Spikey = {
--         { 4, "64b12edbf770ee4f7ffdbb563cab2df2 rune.legacy.heatshot", "Heat Shot" }
--     }
-- }

-- plugin.scan_reward_table = function(enemy, stats)
--     local reward = nil
--     local i = 0
--     local list = plugin.enemy_rank_reward_table[enemy]
--     while i < #list and reward == nil do
--         if reward == nil then i = i + 1 end
--         if stats.score > list[i][1] then
--             reward = list[i]
--             break
--         end
--     end
--     return reward
-- end

--Async.write_file(path, content) -- promise, value = bool
plugin.get_whitelist_for_player = function(player_id)
    return Async.create_scope(function()
        local player_memory = player_data.get_player_data(player_id)
        local whitelist_to_read = player_memory.whitelist_path
        if whitelist_to_read == nil then
            return plugin.create_whitelist_for_player(player_id)
        end
        return whitelist_to_read
    end)
end

plugin.lines_from = function(file)
    local lines = {}
    for line in io.lines(file) do
        lines[#lines + 1] = line
    end
    return lines
end

plugin.create_whitelist_for_player = function(player_id)
    return Async.create_scope(function()
        local player_memory = player_data.get_player_data(player_id)

        local secret = Net.get_player_secret(player_id)

        local whitelist_to_copy = "./whitelists/MainWhitelist.toml"
        local whitelist_to_create = "./whitelists/" .. tostring(secret) .. ".toml"

        local file_data = Async.read_file(whitelist_to_copy)

        if file_data ~= nil then
            player_memory.whitelist_path = whitelist_to_create
            player_memory.io_whitelist_path = whitelist_to_create

            local content = Async.await(Async.read_file(whitelist_to_copy))

            Async.await(Async.write_file(whitelist_to_create, content))

            Net.update_asset(player_memory.whitelist_path, content)

            player_data.save_player_data(player_id)

            return whitelist_to_create
        end
        return whitelist_to_copy
    end)
end

plugin.append_to_whitelist_for_player = function(player_id, additional_content)
    local player_memory = player_data.get_player_data(player_id)
    local whitelist_for_io = player_memory.io_whitelist_path
    local filehandle = Async.read_file(whitelist_for_io)
    if filehandle ~= nil then
        local lines = plugin.lines_from(whitelist_for_io)
        local already_has = false
        for k, v in pairs(lines) do
            if v == additional_content then
                already_has = true
                break
            end
        end
        if already_has ~= true then
            Async.read_file(whitelist_for_io).and_then(function(current_content)
                Async.write_file(whitelist_for_io, current_content .. "\n" .. additional_content)

                Net.update_asset(player_memory.whitelist_path, current_content .. "\n" .. additional_content)

                Net.set_player_restrictions(player_id, player_memory.whitelist_path)
            end)
            return true
        end
        return false
    end
    return false
end

Net:on("player_connect", function(event)
    return Async.create_scope(function()
        local player_id = event.player_id

        local player_memory = player_data.get_player_data(player_id)

        Net.set_player_restrictions(player_id, player_memory.whitelist_path)
    end)
end)

Net:on("player_request", function(event)
    local player_id = event.player_id

    plugin.get_whitelist_for_player(player_id)
end)

return plugin
