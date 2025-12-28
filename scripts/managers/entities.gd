extends Node

@export var player_scene: PackedScene
@export var enemy_skeleton_scene: PackedScene

@onready var player_multiplayer_spawner: MultiplayerSpawner = $spawned_players/player_multiplayer_spawner
@onready var enemy_multiplayer_spawner: MultiplayerSpawner = $spawned_enemies/enemy_multiplayer_spawner

var player_queue: Array[int] = []	# A list of player ids waiting to spawn
var player_instances = {}			# A dictionary of the player instances
#var enemy_instances = {}			# A dictionary of the spawned enemy instances
var enemy_instances: Array[Enemy]	# An array of the spawned enemy instances


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_multiplayer_authority():
		Levels.all_peers_loaded.connect(_on_all_peers_loaded)
		Events.game_events.player_died.connect(_on_player_died)
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
			Log.pr("No free spawn points for player " + str(this_peer_id))


# This function is called when all the peers have successfully loaded the
# level - it creates the player objects on the server peer, and allows the
# MultiplayerSpawner to then replicate them across the client peers.
func _on_all_peers_loaded() -> void:
	Log.pr(str(get_tree()) + "Spawning Players into Level...")
	
	# Spawn Players
	for peer_id in Network.players:
		player_queue.append(peer_id)
		
	# Spawn Static Enemies
	Log.pr(str(get_tree()) + "Spawning Enemies into Level...")
	
	var spawn_data = {
		"global_position" : Vector2(160, 160),
	}
	var enemy_instance: Enemy = enemy_multiplayer_spawner.spawn(spawn_data)
	enemy_instances.append(enemy_instance)


func _on_player_died(this_peer_id: int) -> void:
	player_instances.erase(this_peer_id)
	player_queue.append(this_peer_id)


func _on_level_complete() -> void:
	Log.pr("Clearing player instances")
	for player_key in player_instances.keys():
		player_instances[player_key].queue_free()
	player_instances.clear()
	Log.pr("Clearing enemy instances")
	for enemy in enemy_instances:
		enemy.queue_free()
	enemy_instances.clear()
	Log.pr("Clearing player waiting to spawn queue")
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
	var this_global_position = data["global_position"]
	var enemy_skeleton_instance = enemy_skeleton_scene.instantiate()
	enemy_skeleton_instance.global_position = this_global_position
	
	# Godot automatically adds the node to the scene tree
	return enemy_skeleton_instance
	
