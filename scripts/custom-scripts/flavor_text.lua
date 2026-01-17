Net:on("object_interaction", function(event)
	local button = event.button
	--Don't do anything if we didn't interact.
	if button ~= 0 then return end
	local player_id = event.player_id
	local object_id = event.object_id
	--Get the area we're currently in.
	local area_id = Net.get_player_area(player_id)
	--Get the object from the relevant area.
	local object = Net.get_object_by_id(area_id, object_id)
	--Grab the flavor text if it exists.
	local flavorText = object.custom_properties.Flavor
	--Put it all in one line. Message the player with the flavor text.
	if flavorText ~= nil then Net.message_player(player_id, flavorText) end
end)