Net:on("shop_leave", function(event)
    -- { player_id: string }
    print("[shop_leave] " .. event.player_id)
    Net.set_shop_message(event.player_id, "See you later!")
end)

Net:on("shop_close", function(event)
    -- { player_id: string }
    print("[shop_close] " .. event.player_id)
    if Net.is_player_input_locked(event.player_id) then Net.unlock_player_input(event.player_id) end
end)

Net:on("shop_purchase", function(event)
    -- { player_id: string, item_id: string }
    print("[shop_purchase] " .. event.player_id, event.item_id)
end)

Net:on("shop_description_request", function(event)
    -- { player_id: string, item_id: string }
    print("[shop_description_request] " .. event.player_id, event.item_id)
end)
