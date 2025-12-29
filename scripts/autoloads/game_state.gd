extends Node

## This autoload keeps track of the overall game state, so that systems can 
## react to changes in the game state.
## If a system wants to request a change to the game state, they use 
## GameState.change_game_state(new_game_state).
## Once the game state is changed the game_state_changed signal is emitted.
## All systems listen for the game_state_changed signal, and must react 
## themselves to the change. This avoids having to call functions directly on 
## all the systems to let them know something happend, which would couple them. 
## This de-coupling is called the 'Observer' pattern.

enum GAME_STATES {
	BOOT_SPLASH,		# Not yet implemented in this game, but we start here anyway.
	MAIN_MENU,
	STEAM_LOBBY_MENU,
	ENET_MENU,
	SCENE_LOADING,
	SCENE_LOADED_WAITING_FOR_ALL_PLAYERS,
	SCENE_UNLOADING,	# State while all the level objects are freed off
	PLAYING,
	PAUSED,
	QUITTING
}

signal game_state_changed(old_game_state: int, new_game_state: int)

var current_game_state: int = GAME_STATES.BOOT_SPLASH

func change_game_state(new_game_state: int) -> void:
	if current_game_state != new_game_state:
		Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Changing game_state from " + GAME_STATES.keys()[current_game_state] + " to " + GAME_STATES.keys()[new_game_state])
		current_game_state = new_game_state
		game_state_changed.emit(current_game_state, new_game_state)
	else:
		Log.warn("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Trying to change game_state from " + GAME_STATES.keys()[current_game_state] + " to " + GAME_STATES.keys()[new_game_state])
