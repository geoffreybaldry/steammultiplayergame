extends Node

@export var player_scene: PackedScene
#@export var enemy_skeleton_scene: PackedScene

@onready var player_multiplayer_spawner: MultiplayerSpawner = $spawned_players/player_multiplayer_spawner
@onready var enemy_multiplayer_spawner: MultiplayerSpawner = $spawned_enemies/enemy_multiplayer_spawner

enum ENEMY_TYPES {
	SKELETON,
}

var enemy_scenes = {
	ENEMY_TYPES.SKELETON: preload("res://scenes/enemies/skeleton.tscn"),
}

var player_queue: Array[int] = []	# A list of player ids waiting to spawn
var player_instances = {}			# A dictionary of the player instances
var enemy_instances: Array[Enemy]	# An array of the spawned enemy instances


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_multiplayer_authority():
		Levels.all_peers_loaded.connect(_on_all_peers_loaded)
		Events.game_events.player_died.connect(_on_player_died)
		Events.game_events.spawn_enemy_request.connect(_on_spawn_enemy_request)
	
	Events.game_events.level_complete.connect(_on_level_complete)

	player_multiplayer_spawner.spawn_function = spawn_player
	enemy_multiplayer_spawner.spawn_function = spawn_enemy


func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	# If a player is waiting to spawn, find a spawn point
	if not player_queue.is_empty():
		var this_peer_id: int = player_queue[0]
		var free_spawn_position = SpawnPoints.get_free_spawn_point_position()
		if free_spawn_position:
			if not player_instances.has(this_peer_id):
				var spawn_data = {
					"peer_id": this_peer_id,
					"global_position": free_spawn_position,
					"player_color": Network.seats.find(this_peer_id)
				}
				var player_instance:Player = player_multiplayer_spawner.spawn(spawn_data)
				player_instances[this_peer_id] = player_instance
				# Remove the waiting player from the queue
				player_queue.pop_front()
		else:
			Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "No free spawn points for player " + str(this_peer_id))


# This function is called when all the peers have successfully loaded the
# level - it creates the player objects on the server peer, and allows the
# MultiplayerSpawner to then replicate them across the client peers.
func _on_all_peers_loaded() -> void:
	Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Spawning Players into Level...")
	
	# Spawn Players
	for peer_id in Network.players:
		player_queue.append(peer_id)
	
	# Move the game state on to "PLAYING" now that all peers are loaded, and all entities created
	#GameState.change_game_state(GameState.GAME_STATES.PLAYING)


func _on_spawn_enemy_request(this_enemy_type: int, this_global_position: Vector2) -> void:
	var spawn_data = {
		"enemy_type" : this_enemy_type,
		"global_position" : this_global_position,
	}
	var enemy_instance: Enemy = enemy_multiplayer_spawner.spawn(spawn_data)
	enemy_instances.append(enemy_instance)


func _on_player_died(this_peer_id: int) -> void:
	player_instances.erase(this_peer_id)
	player_queue.append(this_peer_id)


func _on_level_complete() -> void:
	Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Clearing player instances")
	for player_key in player_instances.keys():
		player_instances[player_key].queue_free()
	player_instances.clear()
	Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Clearing enemy instances")
	for enemy in enemy_instances:
		enemy.queue_free()
	enemy_instances.clear()
	Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Clearing player waiting to spawn queue")
	player_queue.clear()
	

func spawn_player(data: Variant) -> Node:
	var this_peer_id = data["peer_id"]
	var this_global_position = data["global_position"]
	var this_player_color = data["player_color"]
	
	var player_instance = player_scene.instantiate()
	player_instance.peer_id = this_peer_id
	player_instance.name = str(this_peer_id) 
	player_instance.global_position = this_global_position
	player_instance.player_color = this_player_color
	
	# Godot automatically adds the node to the scene tree
	return player_instance


func spawn_enemy(data: Variant) -> Node:
	var this_enemy_type = data["enemy_type"]
	var this_global_position = data["global_position"]
	
	var enemy_instance: Node
	match this_enemy_type:
		ENEMY_TYPES.SKELETON:
			enemy_instance = enemy_scenes[ENEMY_TYPES.SKELETON].instantiate()
		_:
			Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Trying to instantiate Unknown enemy type " + str(this_enemy_type))
			
	enemy_instance.global_position = this_global_position
	
	# Godot automatically adds the node to the scene tree
	return enemy_instance
	
