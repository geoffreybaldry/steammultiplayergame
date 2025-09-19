extends Node

## This autoload must come first in the Globals list. It does not depend on 
## other systems, but other systems may depend upon it.
## This is where globally important signals are defined, so that subsystems
## can use and react to the signals defined here.
## The events defined here are subdivided into different classes, I think mostly
## because it looks cool :-|, but also creates some separation/classification.

var mplayer = MultiplayerEvents.new()

# Use it like Events.mplayer.player_joined.connect(id, name)
class MultiplayerEvents:
	@warning_ignore("unused_signal")
	signal player_joined(player_id, player_display_name)
