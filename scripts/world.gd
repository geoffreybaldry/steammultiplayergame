extends Node2D

## This scene is the root of the game world - Consider it the "Main Scene".
## Other scenes like Main Menu UI, Multiplayer Lobby UI, or the Game's Levels
## are all added or removed as children of this World scene.
## This means that game game never truly "switches" between scenes at the root.
## The World scene persists through the entire execution of the game.
## 
## The draw-back of this is that we probably can't run the individual child
## "level" scenes on their own and expect them to work. However, in a 
## multiplayer game there are so many other systems too, that it never going
## to be easy to do that. 

@onready var ui_canvas_layer: CanvasLayer = $ui_canvas_layer
@onready var main_menu_ui: Control = $ui_canvas_layer/main_menu_ui
@onready var lobby_menu_ui: Control = $ui_canvas_layer/lobby_menu_ui
@onready var scene_loading_ui: Control = $ui_canvas_layer/scene_loading_ui
@onready var pause_menu_ui: Control = $ui_canvas_layer/pause_menu_ui


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect to signals	
	GameState.game_state_changed.connect(_on_game_state_changed)
	
	# At this stage the game_state is now MAIN_MENU
	GameState.change_game_state(GameState.GAME_STATES.MAIN_MENU)
	

func _on_game_state_changed(_old_game_state: int, new_game_state: int) -> void:
	#Log.pr("_on_game_state_changed : ", old_game_state, new_game_state)
	
	main_menu_ui.visible = false
	#main_menu_ui.set_process(false)
	lobby_menu_ui.visible = false
	#lobby_menu_ui.set_process(false)
	scene_loading_ui.visible = false
	#scene_loading_ui.set_process(false)
	pause_menu_ui.visible = false
	#pause_menu_ui.set_process(false) # This must always process to listen for the pause button
	
	match new_game_state:
		GameState.GAME_STATES.MAIN_MENU:
			main_menu_ui.visible = true
			#main_menu_ui.set_process(true)
		GameState.GAME_STATES.LOBBY_MENU:
			lobby_menu_ui.visible = true
			#lobby_menu_ui.set_process(true)
		GameState.GAME_STATES.SCENE_LOADING:
			scene_loading_ui.visible = true
			#scene_loading_ui.set_process(true)
		GameState.GAME_STATES.PLAYING:
			pass
		GameState.GAME_STATES.PAUSED:
			pause_menu_ui.visible = true
