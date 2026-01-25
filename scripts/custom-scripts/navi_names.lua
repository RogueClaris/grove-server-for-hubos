local naviNamePlugin = {}

naviNamePlugin.player_navi_names = {}

Net:on("player_avatar_change", function(event)
    naviNamePlugin.player_navi_names[event.player_id] = event.name
end)

Net:on("player_disconnect", function(event)
    naviNamePlugin.player_navi_names[event.player_id] = nil
end)

return naviNamePlugin
