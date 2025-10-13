extends Control

@onready var loading_container: VBoxContainer = $loading_container
@onready var loading_progress_bar: ProgressBar = $loading_container/loading_progress_bar

@onready var unloading_container: VBoxContainer = $unloading_container
@onready var unloading_progress_bar: ProgressBar = $unloading_container/unloading_progress_bar


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect to signals
	GameState.game_state_changed.connect(_on_game_state_changed)
	
	Levels.scene_loading_progress_updated.connect(_on_scene_loading_progress_updated)


func _on_game_state_changed(_old_game_state: int, new_game_state: int) -> void:
	#Log.pr("_on_game_state_changed : ", _old_game_state, new_game_state)
	
	# Turn on the UI scene we want
	match new_game_state:
		GameState.GAME_STATES.SCENE_LOADING:
			loading_container.visible = true
			unloading_container.visible = false
		GameState.GAME_STATES.SCENE_UNLOADING:
			loading_container.visible = false
			unloading_container.visible = true


# Update the UI progress bar, casting the value to an int parameter
func _on_scene_loading_progress_updated(this_progress_value: int) -> void:
	loading_progress_bar.value = this_progress_value
