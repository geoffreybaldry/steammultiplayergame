extends Control

@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Levels.scene_loading_progress_updated.connect(_on_scene_loading_progress_updated)


# Update the UI progress bar, casting the value to an int parameter
func _on_scene_loading_progress_updated(this_progress_value: int) -> void:
	Log.pr("Received new progress value : " + str(this_progress_value))
	progress_bar.value = this_progress_value
