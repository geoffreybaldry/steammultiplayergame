extends Node

## This autoload must come first in the Globals list. It does not depend on 
## other systems, but other systems may depend upon it.
## This is where globally important signals are defined, so that subsystems
## can use and react to them.
## It's often used as a place to define a signal where defining it elsewhere
## might result in a race-condition or "catch-22".
## I find it better to define signals "closer" to the source of where they are
## used usually, but sometimes it's not possible.
##
## The signals defined here are subdivided into different classes, I think 
## mostly because it looks cool :-|, but also creates some 
## separation/classification.

var mplayer = MultiplayerEvents.new()
var error_messages = ErrorMessages.new()

# Use it like Events.mplayer.player_joined.connect(id, name)
class MultiplayerEvents:
	@warning_ignore("unused_signal")
	signal player_joined(player_id, player_display_name)
	
	
class ErrorMessages:
	@warning_ignore("unused_signal")
	signal error_message(message)
