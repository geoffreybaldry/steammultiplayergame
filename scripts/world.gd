extends Node2D

## This scene is the root of the game world - Consider it the "Main Scene".
## Other scenes like Main Menu UI, Multiplayer Lobby UI, or the Game's Levels
## are all added or removed as children of this World scene.
## This means that game game never truly "switches" between scenes at the root.
## The World scene persists through the entire execution of the game.
## 
## The draw-back of this is that we probably can't run the individual child
## "level" scenes on their own and expect them to work. However, in a 
## multiplayer game there are so many other systems too, that it's never going
## to be easy to do that. 

@onready var ui_canvas_layer: CanvasLayer = $ui_canvas_layer
@onready var main_menu_ui: Control = $ui_canvas_layer/main_menu_ui
@onready var lobby_menu_ui: Control = $ui_canvas_layer/lobby_menu_ui
@onready var enet_menu_ui: Control = $ui_canvas_layer/enet_menu_ui
@onready var scene_loading_ui: Control = $ui_canvas_layer/scene_loading_ui
@onready var pause_menu_ui: Control = $ui_canvas_layer/pause_menu_ui


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Connect to signals
	GameState.game_state_changed.connect(_on_game_state_changed)
	
	# At this stage the game_state is now MAIN_MENU
	#GameState.change_game_state(GameState.GAME_STATES.MAIN_MENU)
	GameState.change_game_state(GameState.GAME_STATES.ENET_MENU)
	

# Show/Hide different UI scenes based on the game state
func _on_game_state_changed(_old_game_state: int, new_game_state: int) -> void:
	#Log.pr("_on_game_state_changed : ", old_game_state, new_game_state)
	
	# Hide all the UI scenes
	main_menu_ui.visible = false
	lobby_menu_ui.visible = false
	enet_menu_ui.visible = false
	scene_loading_ui.visible = false
	pause_menu_ui.visible = false
	
	# Turn on the UI scene we want
	match new_game_state:
		GameState.GAME_STATES.MAIN_MENU:
			main_menu_ui.visible = true
		GameState.GAME_STATES.STEAM_LOBBY_MENU:
			lobby_menu_ui.visible = true
		GameState.GAME_STATES.ENET_MENU:
			enet_menu_ui.visible = true
		GameState.GAME_STATES.SCENE_LOADING:
			scene_loading_ui.visible = true
		#GameState.GAME_STATES.SCENE_LOADED_WAITING_FOR_ALL_PLAYERS:
			#pass
		GameState.GAME_STATES.SCENE_UNLOADING:
			scene_loading_ui.visible = true
		GameState.GAME_STATES.PLAYING:
			pass
		GameState.GAME_STATES.PAUSED:
			pause_menu_ui.visible = true
		GameState.GAME_STATES.QUITTING:
			pass
		_:
			Log.warn("New Game State Not Recognised : " + str(new_game_state))
