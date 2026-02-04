extends Node

enum ENEMY_TYPES {
	SKELETON,
}

@onready var player_multiplayer_spawner: MultiplayerSpawner = $spawned_players/player_multiplayer_spawner
@onready var enemy_multiplayer_spawner: MultiplayerSpawner = $spawned_enemies/enemy_multiplayer_spawner

var player_scene = preload("res://scenes/actors/player/player.tscn")
var enemy_scenes = {
	ENEMY_TYPES.SKELETON: preload("res://scenes/actors/enemies/skeleton/skeleton.tscn"),
}

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var player_queue: Array[int] = []	# A list of player ids waiting to enter the level
var player_instances = {}			# A dictionary of the spawned player instances
var enemy_instances = {}			# An dictionary of the spawned enemy instances

var client_player_instances_spawned: int = 0

func _ready() -> void:
	Levels.all_peers_loaded.connect(_on_all_peers_loaded)
	Events.game_events.register_player_instance.connect(_on_register_player_instance)
	Events.game_events.deregister_player_instance.connect(_on_deregister_player_instance)
	Events.game_events.player_died.connect(_on_player_died)
	
	Events.game_events.spawn_enemy_request.connect(_on_spawn_enemy_request)
	
	# Custom spawn function(s)
	player_multiplayer_spawner.spawn_function = instantiate_player
	enemy_multiplayer_spawner.spawn_function = instantiate_enemy
	

func _process(_delta: float) -> void:
	if not player_queue.is_empty():
		var peer_id = player_queue[0]
		# Find a spawn point for the 1st waiting player
		var spawn_point_position = SpawnPoints.get_free_spawn_point_position()
		if spawn_point_position:
			Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Placing peer id " + str(peer_id) + " at position " + str(spawn_point_position))
			player_instances[peer_id].spawn_tick = NetworkTime.tick + 30
			player_instances[peer_id].spawn_position = spawn_point_position
			player_queue.pop_front()
		else:
			Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "No free spawn points for peer id " + str(peer_id))


func _on_all_peers_loaded():
	# Create any enemies required
	# TBD

	# If we already have all the player instances we need, just put them in the level
	if player_instances.size() == Network.players.size():
		add_player_instances_to_spawn_queue()
	else:
		# Otherwise, create any player instances required
		for peer_id: int in Network.players.keys():
			if not player_instances.has(peer_id):
				spawn_player_instance(peer_id)


func add_player_instances_to_spawn_queue() -> void:
	for peer_id: int in player_instances.keys():
		player_queue.append(peer_id)


func spawn_player_instance(this_peer_id: int) -> void:
	Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "spawn_player_instance() : " + str(this_peer_id))
	var spawn_data = {
		"peer_id": this_peer_id,
		"global_position": Vector2(0, Network.seats.find(this_peer_id) * 32), # Never spawn on top
		"player_color": Network.seats.find(this_peer_id)
	}
	player_multiplayer_spawner.spawn(spawn_data)


#func spawn_player_instance_function(data: Variant) -> Node:
func instantiate_player(data: Variant) -> Node:
	var player_instance = player_scene.instantiate()
	player_instance.peer_id = data["peer_id"]
	player_instance.name = str(data["peer_id"]) 
	player_instance.global_position = data["global_position"]
	player_instance.player_color = data["player_color"]
	
	# Godot automatically adds the node to the scene tree
	return player_instance


func _on_spawn_enemy_request(this_enemy_type: int, this_global_position: Vector2) -> void:
	var spawn_data = {
		"enemy_type": this_enemy_type,
		"global_position": this_global_position,
		"id": generate_id(),
	}
	var enemy_instance = enemy_multiplayer_spawner.spawn(spawn_data)
	enemy_instances[enemy_instance.id] = enemy_instance
	

#func spawn_enemy_instance_function(data: Variant) -> Node:
func instantiate_enemy(data: Variant) -> Node:
	var enemy_instance: Node
	match data["enemy_type"]:
		ENEMY_TYPES.SKELETON:
			enemy_instance = enemy_scenes[ENEMY_TYPES.SKELETON].instantiate()
		_:
			Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Trying to instantiate Unknown enemy type " + str(data["enemy_type"]))
	
	enemy_instance.id = data["id"]
	enemy_instance.name = data["id"]
	enemy_instance.global_position = data["global_position"]
	
	# Godot automatically adds the node to the scene tree
	return enemy_instance
	

func _on_register_player_instance(this_peer_id: int, this_player_instance: Player) -> void:
	Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Registering player instance for peer id " + str(this_peer_id)) 
	if not player_instances.has(this_peer_id):
		player_instances[this_peer_id] = this_player_instance
		if player_instances.size() == Network.players.size():
			# Let the server know that all required player instances are spawned
			all_player_instances_spawned.rpc_id(1)
	else:
		Log.warn("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Trying to register a player instance for peer id " + str(this_peer_id) + " when one alreay exists")


func _on_player_died(this_peer_id: int) -> void:
	Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "_on_player_died() for peer id " + str(this_peer_id))
	
	player_instances[this_peer_id].is_player_enabled = false
	player_queue.append(this_peer_id)


func _on_deregister_player_instance(this_peer_id: int) -> void:
	if not multiplayer.is_server():
		return
		
	if player_instances.has(this_peer_id):
		pass # TBD


@rpc("any_peer", "call_local", "reliable")
func all_player_instances_spawned() -> void:
	if multiplayer.is_server():
		Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "all_player_instances_spawned on peer " + str(multiplayer.get_remote_sender_id()))
		client_player_instances_spawned += 1
		if client_player_instances_spawned == Network.players.size():
			Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "All the clients have spawned all their players.")
			add_player_instances_to_spawn_queue()


func generate_id(length: int = 12, charset: String = "abcdefghijklmnopqrstuvwxyz0123456789") -> String:
	var result = ""

	# Generate a random ID
	for i in range(length):
		var idx = _rng.randi_range(0, charset.length() - 1)
		result += charset[idx]

	return result
