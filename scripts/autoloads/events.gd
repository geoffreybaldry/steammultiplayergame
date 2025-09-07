extends Node
# class_name Events

var mplayer = MultiplayerEvents.new()


# Use it like Events.mplayer.player_joined.connect(id, name)
class MultiplayerEvents:
	@warning_ignore("unused_signal")
	signal player_joined(player_id, player_display_name)
