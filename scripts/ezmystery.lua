local MysteryDataLib = {}
local player_data = require('scripts/custom-scripts/player_data')

local math = require('math')

local object_cache = {}
local revealed_mysteries_for_players = {}

local sfx = {
    item_get = '/server/assets/ezlibs-assets/sfx/item_get.ogg',
}

local function extract_numbered_properties(object, property_prefix)
    local out_table = {}
    for i = 1, 20 do
        local text = object.custom_properties[property_prefix .. i]
        if text then
            out_table[i] = text
        end
    end
    return out_table
end

--Type Mystery Data (or Mystery Datum) have these custom_properties
--Locked (bool) do you need an unlocker to open this?
--Once (bool) should this never respawn for this player?
--Type (string) either 'keyitem' or 'money'
--(for keyitem type)
--    Name (string) name of keyitem
--    Description (string) description of keyitem
--(for money type)
--    Amount (number) amount of money to give

local function object_is_mystery_data(object)
    if object.type == "Mystery Data" or object.type == "Mystery Datum" then
        return true
    end
end

Net:on("object_interaction", function(event)
    -- { player_id: string, object_id: number, button: number }

    local area_id = Net.get_player_area(event.player_id)
    local object = Net.get_object_by_id(area_id, event.object_id)
    if object_is_mystery_data(object) then
        MysteryDataLib.try_collect_datum(event.player_id, area_id, object)
    end
end)

Net:on("player_disconnect", function(event)
    local player_id = event.player_id
    revealed_mysteries_for_players[player_id] = nil
end)

function MysteryDataLib.hide_random_data(player_id)
    local area_id = Net.get_player_area(player_id)
    local objects = Net.list_objects(area_id)
    --New map properties. Default to making maximum smaller than minimum so that if this isn't setup, it won't be used.
    local area_min_mystery_count = tonumber(Net.get_area_custom_property(area_id, "Mystery Data Minimum")) or 1
    local area_max_mystery_count = tonumber(Net.get_area_custom_property(area_id, "Mystery Data Maximum")) or 0
    --As mentioned, don't do anything if the min is smaller than the max. Safety!
    if area_min_mystery_count > area_max_mystery_count then return end
    --If we don't have a record of this player upon transfer (due to reasons like joining in an area without randomized data), then process this player
    if revealed_mysteries_for_players[player_id] == nil then revealed_mysteries_for_players[player_id] = {} end
    --If we've already processed this area for this player, don't process. We don't want to process the same area twice.
    --That way, we don't rearrange existing mystery data, or data that's already been hidden.
    if revealed_mysteries_for_players[player_id] and revealed_mysteries_for_players[player_id][area_id] then
        return
    end
    --Mystery count used in the loop.
    local mystery_count = 0
    --Amount of mystery data to be found in the area.
    local desired_mystery_count = math.random(area_min_mystery_count, area_max_mystery_count)
    --Add the area to a dict of player memory. Since we've started processing this area, we don't want to process it again.
    revealed_mysteries_for_players[player_id][area_id] = {}
    local datum_list = {}
    for i, object_id in next, objects do
        local object = Net.get_object_by_id(area_id, object_id)
        --Only allow in to the list if it's a mystery datum that is not set to one-time and it's not locked.
        if object_is_mystery_data(object) and object.custom_properties["Once"] ~= "true" and object.custom_properties["Locked"] ~= "true" then
            --Add to the list.
            table.insert(datum_list, object.id)
            --Increment count since we found a datum.
            mystery_count = mystery_count + 1
        end
    end
    while mystery_count > desired_mystery_count do
        --Get random mystery index.
        local index = math.random(#datum_list)
        --Get random mystery ID.
        local mystery = datum_list[index]
        --If it's not already removed, then...
        if mystery ~= nil then
            --Hide it.
            player_data.hide_target_from_player(player_id, area_id, mystery, "OBJECT")

            --Remove it.
            table.remove(datum_list, index)

            --Reassign the mystery count.
            mystery_count = #datum_list
        end
    end
    revealed_mysteries_for_players[player_id][area_id] = datum_list
end

Net:on("player_area_transfer", function(event)
    local player_id = event.player_id
    MysteryDataLib.hide_random_data(player_id)
end)

Net:on("player_join", function(event)
    local player_id = event.player_id
    --Load sound effects for mystery data interaction
    for name, path in pairs(sfx) do
        Net.provide_asset_for_player(player_id, path)
    end
    MysteryDataLib.hide_random_data(player_id)
end)

MysteryDataLib.try_collect_datum = Async.create_function(function(player_id, area_id, object)
    if player_data.is_target_hidden(player_id, area_id, object.id, "OBJECT") then
        --Anti spam protection
        return
    end

    if object.custom_properties["Locked"] == "true" then
        Async.await(Async.message_player(player_id, "The Mystery Data is locked."))
        if player_data.count_player_item(player_id, "Unlocker") > 0 then
            local response = Async.await(Async.question_player(player_id, "Use an Unlocker to open it?"))
            if response == 1 then
                player_data.update_player_item(player_id, "Unlocker", -1)

                Async.await(MysteryDataLib.collect_datum(player_id, object, object.id))
            end
        end
    else
        --If the data is not locked, collect it
        Async.await(Async.message_player(player_id, "Accessing the mystery data\x01...\x01"))
        Async.await(MysteryDataLib.collect_datum(player_id, object, object.id))
    end
end)


MysteryDataLib.validate_datum = function(object)
    local type = object.custom_properties["Type"]
    local return_value = true

    if type == "random" then
        local random_options = extract_numbered_properties(object, "Next ")
        if #random_options == 0 then
            warn('[MysteryDataLib] ' .. object.id .. ' is type=random, but has no Next #')
            return_value = false
        end
    elseif type == "money" then
        local amount = object.custom_properties["Amount"]
        if not amount then
            warn('[MysteryDataLib] ' .. object.id .. ' has no amount')
            return_value = false
        end
    else
        local item = {
            name = object.custom_properties["Name"] or nil,
            description = object.custom_properties["Description"] or nil,
            consumable = type == "consumable",
        }

        if type == "keyitem" and (item.name == nil or item.description == nil) then
            warn('[MysteryDataLib] ' .. object.id .. ' has either no name or description')
            return_value = false
        elseif type == "item" and not item.name then
            warn('[MysteryDataLib] ' .. object.id .. ' has no name')
            return_value = false
        else
            warn('[MysteryDataLib] invalid type for mystery data ' .. object.id .. " type= " .. tostring(type))
            return_value = false
        end
    end

    return return_value
end

MysteryDataLib.collect_datum = Async.create_function(function(player_id, object, datum_id_override)
    local area_id = Net.get_player_area(player_id)

    if not MysteryDataLib.validate_datum(object) then
        return
    end

    local type = object.custom_properties["Type"]
    local randomly_selected_datum;

    if type == "random" then
        local random_options = extract_numbered_properties(object, "Next ")
        local random_selection_id = random_options[math.random(#random_options)]
        if random_selection_id then
            randomly_selected_datum = Net.get_object_by_id(area_id, random_selection_id)
            Async.await(MysteryDataLib.collect_datum(player_id, randomly_selected_datum, datum_id_override))
            return
        end
    elseif type == "keyitem" then
        local name = object.custom_properties["Name"]
        local description = object.custom_properties["Description"]

        --Give the player an item
        player_id.update_player_item(player_id, name, 1)

        Net.message_player(player_id, "Got " .. name .. "!")
        Net.play_sound_for_player(player_id, sfx.item_get)
    elseif type == "item" then
        local name = object.custom_properties["Name"]
        --Give the player an item

        player_id.update_player_item(player_id, name, 1)

        Net.message_player(player_id, "Got " .. name .. "!")
        Net.play_sound_for_player(player_id, sfx.item_get)
    elseif type == "money" then
        local amount = object.custom_properties["Amount"]
        --Give the player money

        player_data.update_player_money(player_id, amount)

        Net.message_player(player_id, "Got " .. amount .. "$!")
        Net.play_sound_for_player(player_id, sfx.item_get)
    end

    if object.custom_properties["Once"] == "true" then
        -- Permanently remove datum object.
        player_data.hide_target_from_player(player_id, area_id, datum_id_override, "OBJECT", true)
    else
        -- Temporarily remove datum object
        player_data.hide_target_from_player(player_id, area_id, datum_id_override, "OBJECT", false)
    end
end)


return MysteryDataLib
