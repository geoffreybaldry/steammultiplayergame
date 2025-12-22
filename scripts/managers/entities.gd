extends Node

@export var player_scene: PackedScene
@export var enemy_skeleton_scene: PackedScene

@onready var player_multiplayer_spawner: MultiplayerSpawner = $spawned_players/player_multiplayer_spawner
@onready var enemy_multiplayer_spawner: MultiplayerSpawner = $spawned_enemies/enemy_multiplayer_spawner

var player_queue: Array[int] = []	# A list of player ids waiting to spawn
var player_instances = {}			# A dictionary of the player instances


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_multiplayer_authority():
		NetworkTime.on_tick.connect(_tick)
		Levels.all_peers_loaded.connect(_on_all_peers_loaded)
		Events.game_events.player_died.connect(_on_player_died)
		
	player_multiplayer_spawner.spawn_function = spawn_player
	enemy_multiplayer_spawner.spawn_function = spawn_enemy


func _tick(_dt:float, _tk: int) -> void:
	if not is_multiplayer_authority():
		return
	
	# If a player is waiting to spawn, find a spawn point
	if player_queue:
		var this_peer_id: int = player_queue[0]
		if SpawnPoints.has_free_spawn_point():
			if not player_instances.has(this_peer_id):
				# Spawn a brand new player instance
				Log.pr("Spawning a brand new instance for peer id " + str(this_peer_id))
				#spawn_player(player_queue.pop_front(), SpawnPoints.get_free_spawn_point_position())
				var spawn_data = {
					"peer_id": player_queue.pop_front(),
					"global_position": SpawnPoints.get_free_spawn_point_position(),
				}
				player_multiplayer_spawner.spawn(spawn_data)
			else:
				# Re-position the player instance on a spawn point
				Log.pr("Re-positioning instance for peer id " + str(this_peer_id))
				player_instances[this_peer_id].respawn_position = SpawnPoints.get_free_spawn_point_position()
				player_queue.pop_front()
		else:
			Log.pr("No free spawn points for player " + str(this_peer_id) + " on tick " + str(_tk))
			



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
	enemy_multiplayer_spawner.spawn(spawn_data)


func _on_player_died(this_peer_id: int) -> void:
	player_queue.append(this_peer_id)


func spawn_player(data: Variant) -> Node:
	var this_peer_id = data["peer_id"]
	var this_global_position = data["global_position"]
	
	var player_instance = player_scene.instantiate()
	player_instance.peer_id = this_peer_id
	player_instance.name = str(this_peer_id) 
	player_instance.global_position = this_global_position
	
	# Godot automatically adds the node to the scene tree
	return player_instance


func spawn_enemy(data: Variant) -> Node:
	var this_global_position = data["global_position"]
	var enemy_skeleton_instance = enemy_skeleton_scene.instantiate()
	enemy_skeleton_instance.global_position = this_global_position
	
	# Godot automatically adds the node to the scene tree
	return enemy_skeleton_instance
	
