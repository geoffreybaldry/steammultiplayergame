extends Node2D

## This scene is the root of the game world - Consider it the "Main Scene".
## Other scenes like Main Menu UI, Multiplayer Lobby UI, or the Game's Levels
## are all added or removed as children of this World scene.
## This means that game game never truly "switches" between scenes at the root.
## The World scene persists through the entire execution of the game.
##


@onready var ui_canvas_layer: CanvasLayer = $ui_canvas_layer
@onready var main_menu_ui: Control = $ui_canvas_layer/main_menu_ui
@onready var lobby_menu_ui: Control = $ui_canvas_layer/lobby_menu_ui
@onready var loading_screen_ui: Control = $ui_canvas_layer/loading_screen


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.current_game_state = GameState.MAIN_MENU
	
	# Connect to signals
	main_menu_ui.lobby_menu_button_pressed.connect(_on_lobby_menu_button_pressed)
	lobby_menu_ui.main_menu_button_pressed.connect(_on_main_menu_button_pressed)
	
	Levels.scene_loading.connect(_on_scene_loading)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
	
func _on_lobby_menu_button_pressed() -> void:
	main_menu_ui.visible = false
	lobby_menu_ui.visible = true
	
func _on_main_menu_button_pressed() -> void:
	main_menu_ui.visible = true
	lobby_menu_ui.visible = false
	
func _on_scene_loading() -> void:
	loading_screen_ui.visible = true
