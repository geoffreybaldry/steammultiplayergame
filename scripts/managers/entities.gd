extends Node

@export var player_scene: PackedScene

@onready var player_multiplayer_spawner: MultiplayerSpawner = $spawned_players/player_multiplayer_spawner
@onready var enemy_multiplayer_spawner: MultiplayerSpawner = $spawned_enemies/enemy_multiplayer_spawner
@onready var timer: Timer = $Timer

enum ENEMY_TYPES {
	SKELETON,
}

var enemy_scenes = {
	ENEMY_TYPES.SKELETON: preload("res://scenes/enemies/skeleton.tscn"),
}

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var player_queue: Array[int] = []	# A list of player ids waiting to spawn
var player_instances = {}			# A dictionary of the spawned player instances
var enemy_instances = {}			# An dictionary of the spawned enemy instances


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Network.peer_id_changed.connect(_on_peer_id_changed)
	
	# Custom spawn functions
	player_multiplayer_spawner.spawn_function = spawn_player
	enemy_multiplayer_spawner.spawn_function = spawn_enemy


# When this peer starts as a server it must keep track of the below signals
func _on_peer_id_changed(_old_peer_id: int, new_peer_id: int) -> void:
	# If going from not connected state to server state, connect the server signals
	match new_peer_id:
		0:	# We disconnected from networking
			# If we were the server, disconnect the server signals
			if _old_peer_id == 1:
				disconnect_game_signals()
		1:	# We became the server
			connect_game_signals()
		_:	# We became a client
			pass


func connect_game_signals() -> void:
		Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Entities Connecting to server signals")
		Levels.all_peers_loaded.connect(_on_all_peers_loaded)
		Levels.remove_entities.connect(_on_remove_entities)
		Events.game_events.player_died.connect(_on_player_died)
		Events.game_events.enemy_died.connect(_on_enemy_died)
		Events.game_events.spawn_enemy_request.connect(_on_spawn_enemy_request)
		Network.peer_disconnected.connect(_on_peer_disconnected)


func disconnect_game_signals() -> void:
		Log.warn("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Entities Disconnecting to server signals")
		Levels.all_peers_loaded.disconnect(_on_all_peers_loaded)
		Levels.remove_entities.disconnect(_on_remove_entities)
		Events.game_events.player_died.disconnect(_on_player_died)
		Events.game_events.enemy_died.disconnect(_on_enemy_died)
		Events.game_events.spawn_enemy_request.disconnect(_on_spawn_enemy_request)
		Network.peer_disconnected.disconnect(_on_peer_disconnected)


func _process(_delta: float) -> void:
	pass
	

func _on_peer_disconnected(this_peer_id: int) -> void:
	Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Removing player instance for disconnected peer " + str(this_peer_id))
	_free_entity(player_instances[this_peer_id])
	player_instances.erase(this_peer_id)


# This function is called when all the peers have successfully loaded the
# level - it creates the player objects on the server peer, and allows the
# MultiplayerSpawner to then replicate them across the client peers.
func _on_all_peers_loaded() -> void:
	Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Spawning Players into Level...")
	
	# Spawn Players
	for peer_id in Network.players:
		player_queue.append(peer_id)


func _on_spawn_enemy_request(this_enemy_type: int, this_global_position: Vector2) -> void:
	var spawn_data = {
		"enemy_type": this_enemy_type,
		"global_position": this_global_position,
		"id": generate_id(),
	}
	var enemy_instance: Enemy = enemy_multiplayer_spawner.spawn(spawn_data)
	enemy_instances[enemy_instance.id] = enemy_instance


func _on_player_died(this_peer_id: int) -> void:
	player_instances.erase(this_peer_id)
	player_queue.append(this_peer_id)


func _on_enemy_died(this_id: String) -> void:
	if enemy_instances.has(this_id):
		Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Freeing enemy with id : " + this_id)
		enemy_instances[this_id].queue_free()
		enemy_instances.erase(this_id)


func _on_remove_entities() -> void:
	Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Clearing player waiting to spawn queue")
	player_queue.clear()
	
	Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Clearing player instances")
	for player_key in player_instances.keys():
		_free_entity(player_instances[player_key])
	player_instances.clear()
	
	Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Clearing enemy instances")
	for enemy_id in enemy_instances.keys():
		_free_entity(enemy_instances[enemy_id])
	enemy_instances.clear()
	
	await get_tree().create_timer(2.5).timeout
	
	Levels.entities_removed.emit()


func _free_entity(instance: Node) -> void:
	# Disable the peer's RBS, and make it ready for freeing
	instance.disable_entity.rpc()
	# Let the in-flight RPCs drain
	await get_tree().create_timer(2.0).timeout
	# Queue Free the entity
	var script_global_name: String = instance.get_script().get_global_name()
	match script_global_name:
		"Player":
			Log.pr("Freeing Type (Player): " + str(instance.peer_id))
		"":
			Log.pr("Freeing Type (Not Set): " + str(instance.id))
		_:
			Log.pr("Freeing Type (" + script_global_name + "): " + str(instance.id))
			
	instance.queue_free()


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
	var this_id = data["id"]
	
	var enemy_instance: Node
	match this_enemy_type:
		ENEMY_TYPES.SKELETON:
			enemy_instance = enemy_scenes[ENEMY_TYPES.SKELETON].instantiate()
		_:
			Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Trying to instantiate Unknown enemy type " + str(this_enemy_type))
	
	enemy_instance.id = this_id
	enemy_instance.global_position = this_global_position
	
	# Godot automatically adds the node to the scene tree
	return enemy_instance
	
	
func generate_id(length: int = 12, charset: String = "abcdefghijklmnopqrstuvwxyz0123456789") -> String:
	var result = ""

	# Generate a random ID
	for i in range(length):
		var idx = _rng.randi_range(0, charset.length() - 1)
		result += charset[idx]

	return result


func _on_timer_timeout() -> void:
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
				Log.warn("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Trying to spawn a peer_id that already has an instance. Peer ID : " + str(this_peer_id))
		else:
			Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "No free spawn points for player " + str(this_peer_id))

	# Restart the timer
	timer.start()
	
