extends Node

var loading_screen = preload("res://scenes/ui/loading_screen.tscn")

signal scene_loading
signal scene_loading_progress_updated(progress_percent: int)
signal scene_loaded(scene_filepath: String)

var scene_filepath: String = ""
var progress_value: float = 0.0:
	set (value):
		# If the progress changes, emit a signal for the progress UI
		if value != progress_value:
			Log.pr("New value: " + str(value))
			scene_loading_progress_updated.emit(value)
		progress_value = value
	get:
		return progress_value
		


func _ready() -> void:
	# Connect Local Signals
	scene_loaded.connect(_on_scene_loaded)
	
	Log.pr("Current Scene : " + str(get_tree().current_scene))


func _process(_delta: float) -> void:
	if not scene_filepath:
		return
		
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(scene_filepath, progress)

	match status:
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
			scene_filepath = ""
			Log.pr("Failed to load scene (Invalid Resource): " + str(scene_filepath))
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
			progress_value = progress[0] * 100
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
			scene_filepath = ""
			Log.pr("Failed to load scene (Load Failed): " + str(scene_filepath))
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
			progress_value = 100.0
			scene_loaded.emit(scene_filepath)
			scene_filepath = ""


# When the server decides to start the game from a UI scene,
# do Levels.goto_scene.rpc(scene_filepath)
@rpc("call_local", "reliable")
func goto_scene(this_scene_filepath: String) -> void:
	# Show the Loading Screen Scene, which updates as the level is loaded
	get_tree().change_scene_to_packed(loading_screen)
	
	# Start the asynchronous loading of the desired scene
	load_scene(this_scene_filepath)


func load_scene(this_scene_filepath: String) -> void:
	scene_filepath = this_scene_filepath
	var err = ResourceLoader.load_threaded_request(scene_filepath)
	if err != OK:
		Log.pr("Error Loading Scene path " + str(scene_filepath) + " Error : " + error_string(err))

	# Send this out so UI can present a Nice Loading Overlay, etc.
	scene_loading.emit()


func _on_scene_loaded(this_scene_filepath: String) -> void:
	Log.pr("Scene Loaded Asynchronously.")
	
	# Pause for a short time, so the loading screen is visible
	await get_tree().create_timer(1.5).timeout

	# Now it's time to switch from the current scene to the newly loaded one
	deferred_goto_scene.call_deferred(this_scene_filepath)
	

func deferred_goto_scene(this_scene_filepath: String) -> void:
	# Get a handle on the already background-loaded scene - should not block main thread
	var new_scene_resource = ResourceLoader.load_threaded_get(this_scene_filepath)
	
	# Instantiate the new scene
	var new_scene = new_scene_resource.instantiate()
	
	# It is now safe to remove the current scene.
	get_tree().current_scene.free()
	
	# Add the new scene as the active scene, as child of root.
	get_tree().root.add_child(new_scene)

	# Optionally, to make it compatible with the SceneTree.change_scene_to_file() API.
	get_tree().current_scene = new_scene
	
