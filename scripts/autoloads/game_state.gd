extends Node

## This autoload keeps track of the overall game state, so that systems can 
## react to changes in the game state.

var current_game_state: int = GAME_STATES.BOOT_SPLASH

signal game_state_changed(old_game_state: int, new_game_state: int)

enum GAME_STATES {
	BOOT_SPLASH,
	MAIN_MENU,
	LOBBY_MENU,
	SCENE_LOADING,
	PLAYING,
	PAUSED,
	QUITTING
}


func change_game_state(new_game_state: int) -> void:
	if current_game_state != new_game_state:
		Log.pr("Changing game_state from " + GAME_STATES.keys()[current_game_state] + " to " + GAME_STATES.keys()[new_game_state])
		current_game_state = new_game_state
		game_state_changed.emit(current_game_state, new_game_state)
	else:
		Log.error("Trying to change game_state from " + GAME_STATES.keys()[current_game_state] + " to " + GAME_STATES.keys()[new_game_state])
		
