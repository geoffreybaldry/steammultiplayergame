extends Node

@export var player_scene: PackedScene
@export var enemy_skeleton_scene: PackedScene

@onready var spawned_players: Node = $spawned_players
@onready var spawned_enemies: Node = $spawned_enemies

var player_queue: Array[int] = []	# A list of player ids waiting to spawn
var player_instances = {}			# A dictionary of the player instances


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_multiplayer_authority():
		NetworkTime.on_tick.connect(_tick)
		Levels.all_peers_loaded.connect(_on_all_peers_loaded)
		Events.game_events.player_died.connect(_on_player_died)


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
				spawn_player(player_queue.pop_front(), SpawnPoints.get_free_spawn_point_position())
			else:
				# Re-position the player instance on a spawn point
				Log.pr("Re-positioning instance for peer id " + str(this_peer_id))
				player_instances[this_peer_id].respawn_position = SpawnPoints.get_free_spawn_point_position()
				#player_instances[this_peer_id].enabled = true
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
	spawn_enemy(Vector2(130, 130))
	spawn_enemy(Vector2(160, 160))


func _on_player_died(this_peer_id: int) -> void:
	player_queue.append(this_peer_id)


# This function only happens on the server - the MultiplayerSpawner replicates 
# any spawned player nodes on all the peer clients.
func spawn_player(this_peer_id: int, this_position: Vector2) -> void:
	Log.pr(str(get_tree()) + "Spawning player with id : " + str(this_peer_id))
	
	# Instantiate a player scene, and give it the correct peer id
	var player_instance = player_scene.instantiate()
	player_instance.peer_id = this_peer_id
	
	# This makes the player node in the scene tree have the player's id as its name
	# Useful for debugging in the "remote" scene view, and also for later despawning if necessary
	player_instance.name = str(this_peer_id) 
	
	# Set the player's position to a random offst from an initial value - replace this with spawn pads later)
	player_instance.position = this_position
	
	# Set the color of the player
	player_instance.player_color = Network.seats.find(this_peer_id)
	
	# Add the player instance to the scene tree, under the MultiplayerSpawner's spawn path.
	# This causes the instance to also be spawned on all the client peers too.
	# We add the 'true' argument to force readable names - required by MultiplayerSpawner.
	spawned_players.call_deferred("add_child", player_instance, true)
	
	# Add the instantiated scene to the player instances dictionary
	player_instances[this_peer_id] = player_instance


func spawn_enemy(this_position: Vector2) -> void:
	Log.pr(str(get_tree()) + "Spawning enemy")
	var enemy_skeleton_instance = enemy_skeleton_scene.instantiate()
	enemy_skeleton_instance.global_position = this_position
	spawned_enemies.call_deferred("add_child", enemy_skeleton_instance, true)
