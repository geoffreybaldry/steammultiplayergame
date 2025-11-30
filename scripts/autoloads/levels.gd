extends Node

## This Autoload is in charge of loading and switching between scenes.
## The scenes it switches between are always added or removed as children of the 
## main scene, called World.

signal scene_loading_progress_updated(progress_percent: int)
signal scene_loaded(scene_filepath: String)
signal scene_unloaded
signal all_peers_loaded						# Emitted when all peers have loaded the chosen level

var scene_filepath: String = ""			# e.g. "res://scenes/levels/test_level.tscn"
var current_scene_name: String = ""
var progress_value: float = 0.0:
	set (value):
		# If the progress changes, emit a signal for the progress UI
		if value != progress_value:
			scene_loading_progress_updated.emit(value)
		progress_value = value
	get:
		return progress_value

# A list of all the games scenes
var scenes = [
	"res://scenes/levels/level_1.tscn"
]

# Start the index pointing at the first element in scenes
var next_scene_idx:int = 0

# Used by the server to keep track of how many players have loaded the level
var players_loaded: int = 0

func _ready() -> void:
	# Connect Signals
	#GameState.game_state_changed.connect(_on_game_state_changed)
	scene_loaded.connect(_on_scene_loaded)


# This monitors the progress of any background scene loading taking place
# It emits a scene loaded signal if it notices a background load has completed
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


# Watch for changes in game state, and react accordingly
#func _on_game_state_changed(_old_game_state: int, new_game_state: int) -> void:
	#match new_game_state:
		#GameState.GAME_STATES.MAIN_MENU:
			## Unload any existing level scene
			#if current_scene_name:
				## Destroy any objects in the current scene - Players, Enemies, Projectiles
				## TBD - destroy objects
				#
				## Remove the remaining scene
				#remove_current_scene()
		#GameState.GAME_STATES.SCENE_UNLOADING:
			#pass


# Go to a specific scene, by index
@rpc("call_local", "reliable")
func goto_scene(idx: int) -> void:
	Log.pr("Loading scene : " + scenes[idx])
	# Start the asynchronous loading of the desired scene
	load_scene(scenes[idx])
	next_scene_idx = idx + 1

@rpc("call_local", "reliable")
func goto_next_scene() -> void:
	Log.pr("Loading scene : " + scenes[next_scene_idx])
	# Start the asynchronous loading of the desired scene
	load_scene(scenes[next_scene_idx])
	next_scene_idx += 1


func load_scene(this_scene_filepath: String) -> void:
	scene_filepath = this_scene_filepath
	var err = ResourceLoader.load_threaded_request(scene_filepath)
	if err != OK:
		Log.pr("Error Loading Scene path " + str(scene_filepath) + " Error : " + error_string(err))

	# Change the game_state so UI can present a nice Loading Overlay, etc.
	GameState.change_game_state(GameState.GAME_STATES.SCENE_LOADING)


func _on_scene_loaded(this_scene_filepath: String) -> void:
	# Pause for a short time, so even if the load takes 0.01sec, the loading screen is visible
	await get_tree().create_timer(0.75).timeout

	# Now it's time to switch from the current scene to the newly loaded one
	deferred_goto_scene.call_deferred(this_scene_filepath)
	

func deferred_goto_scene(this_scene_filepath: String) -> void:
	# Get a handle on the already background-loaded scene - should not block main thread
	var new_scene_resource = ResourceLoader.load_threaded_get(this_scene_filepath)
	
	# Instantiate the new scene
	var new_scene_instance: Node2D = new_scene_resource.instantiate()
	#new_scene_instance.name = "current_level"
	
	# Remove the old level scene, if there is one
	if current_scene_name:
		remove_current_scene()
	
	# Add the new scene in its place
	get_tree().current_scene.get_node("levels").add_child(new_scene_instance, true)
	current_scene_name = new_scene_instance.name
	
	GameState.change_game_state(GameState.GAME_STATES.PLAYING)
	
	
func remove_current_scene() -> void:
	Log.pr("Unloading current level scene : " + current_scene_name)
	get_tree().current_scene.get_node("levels").get_node(current_scene_name).queue_free()
	current_scene_name = ""
	scene_unloaded.emit()
	
	
func return_to_main_menu() -> void:
	Log.pr("Returning to Main Menu")
	
	# No use for NetworkTime ticks if we are returning to the Main Menu
	NetworkTime.stop()
	
	# This change in game-state will be seen by the level, and cause it to take action
	GameState.change_game_state(GameState.GAME_STATES.SCENE_UNLOADING)
	
	# Pause for a short time, so even if the load takes 0.01sec, the loading screen is visible
	await get_tree().create_timer(1.5).timeout
	
	# Tell the current level to unload all its entities
	# TBD
	
	# Remove the current level
	remove_current_scene()
	
	GameState.change_game_state(GameState.GAME_STATES.MAIN_MENU)


# Every peer will call this when they have loaded the game scene.
# Only the server needs to keep track of the number of players loaded.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	Log.pr("Player loaded scene - Player ID : " + str(multiplayer.get_remote_sender_id()))
	if multiplayer.is_server():
		players_loaded += 1
		Log.pr("Players in game : " + str(players_loaded) + "/" + str(Network.players.size()))
		if players_loaded == Network.players.size():
			Log.pr("All required players in game : " + str(players_loaded) + "/" + str(Network.players.size()))
			all_peers_loaded.emit()
			players_loaded = 0
