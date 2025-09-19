extends Node

## This autoload keeps track of the overall game state, so that systems can 
## react to changes in the game state.

var current_game_state = BOOT_SPLASH

enum {
	BOOT_SPLASH,
	MAIN_MENU,
	LOBBY_MENU,
	LEVEL_LOADING,
	PLAYING,
	PAUSED,
}
