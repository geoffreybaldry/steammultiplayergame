extends Node

## This autoload must come first in the Globals list. It does not depend on 
## other systems, but other systems may depend upon it.
## This is where globally important signals are defined, so that subsystems
## can use and react to them.
## It's often used as a place to define a signal where defining it elsewhere
## might result in a race-condition or "catch-22". i.e if two systems want
## to connect to eachother's signals, but they can't during start-up because
## one of them doesn't yet exist.
## I find it better to define signals "closer" to the source of where they are
## used usually, but sometimes it's not possible.
##
## The signals defined here are subdivided into different classes, I think 
## mostly because it looks cool :-|, but also creates some 
## separation/classification.

var mplayer_events = MultiplayerEvents.new()
var error_messages = ErrorMessages.new()
var game_events = GameEvents.new()

# Use it like Events.mplayer_events.player_joined.connect(id, name)
class MultiplayerEvents:
	@warning_ignore("unused_signal")
	signal player_joined(peer_id: int, player_display_name: String)
	
	
class ErrorMessages:
	@warning_ignore("unused_signal")
	signal error_message(message: String, duration: float)
	
	
class GameEvents:
	@warning_ignore("unused_signal")
	signal spawn_enemy_request(enemy_type: int, global_position: Vector2)
	
	@warning_ignore("unused_signal")
	signal player_died(peer_id: int)
	
	@warning_ignore("unused_signal")
	signal enemy_died(id: String)
	
	#@warning_ignore("unused_signal")
	#signal level_ready_to_start			# Used to signal that the level is ready to start
	
	#@warning_ignore("unused_signal")
	#signal level_complete				# Used to signal that the level is complete
