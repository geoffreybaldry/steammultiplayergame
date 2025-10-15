extends Node2D

# Temporary help in stopping players spawning on top of eachother
const SPAWN_RANDOM: int = 25

@export var player_scene: PackedScene
@export var enemy_skeleton_scene: PackedScene

@onready var spawned_players: Node2D = $spawned_players
@onready var spawned_enemies: Node2D = $spawned_enemies

#signal level_entities_unloaded

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect to signals
	if multiplayer.is_server():
		#Log.warn("I'm the server")
		Network.all_peers_loaded.connect(_on_all_peers_loaded)
		Network.peer_disconnected.connect(_on_peer_disconnected)
	else:
		#Log.warn("I'm a client")
		Network.server_disconnected.connect(_on_server_disconnected)
		
	# Let the Network Server know that we have loaded the level
	Network.player_loaded.rpc_id(1)
	
	#GameState.game_state_changed.connect(_on_game_state_changed)


#func _on_game_state_changed(_old_game_state: int, new_game_state: int) -> void:
	##Log.pr("_on_game_state_changed : ", old_game_state, new_game_state)
	#
	#match new_game_state:
		#GameState.GAME_STATES.SCENE_UNLOADING:
			#unload_level_entities()


# This function is called when all the peers have successfully loaded the
# level - it creates the player objects on the server peer, and allows the
# MultiplayerSpawner to then replicate them across the client peers.
func _on_all_peers_loaded() -> void:
	Log.pr(str(get_tree()) + "Spawning Players into Level...")
	for this_player in Network.players:
		spawn_player(this_player)
		
	Log.pr(str(get_tree()) + "Spawning Enemies into Level...")
	spawn_enemy()


# This only runs on the server, and removes the peer's player.
# This despawn is then replicated to the client peers
func _on_peer_disconnected(peer_id: int) -> void:
	spawned_players.get_node(str(peer_id)).queue_free()
	
	
func _on_server_disconnected() -> void:
	Log.warn("Server got disconnected!")
	
	# No sense carrying on the charade, we've lost the server!
	#NetworkTime.stop()
	
	#unload_level_entities()	# Not sure if this graceful removal of spawned entities is needed
	Levels.return_to_main_menu()


# Used to gracefully remove any networked entities before unloadng the level.
#func unload_level_entities() -> void:
	#Log.pr("unload_level_entities()")
	#
	## Despawn the player(s)
	#for player in spawned_players.get_children():
		#player.queue_free()
	#
	## Despawn the enemy(ies)
	#for enemy in spawned_enemies.get_children():
		#enemy.queue_free()
		#
	## Despawn projectile(s)
	## TBD
	
	#level_entities_unloaded.emit()
	
# This function only happens on the server - the MultiplayerSpawner replicates 
# any spawned player nodes on all the peer clients.
func spawn_player(this_peer_id: int) -> void:
	Log.pr(str(get_tree()) + "Spawning player with id : " + str(this_peer_id))
	
	# Instantiate a player scene, and give it the correct peer id
	var player_instance = player_scene.instantiate()
	player_instance.peer_id = this_peer_id
	
	# This makes the player node in the scene tree have the player's id as its name
	# Useful for debugging in the "remote" scene view, and also for later despawning if necessary
	player_instance.name = str(this_peer_id) 
	
	# Set the player's position to a random offset from an initial value - replace this with spawn pads later
	var pos: Vector2 = Vector2.from_angle(randf() * 2 * PI)
	player_instance.position = Vector2(50, 120) + Vector2(pos.x * SPAWN_RANDOM * randf(), pos.y * SPAWN_RANDOM * randf())
	
	# Add the player instance to the scene tree, under the MultiplayerSpawner's spawn path.
	# This causes the instance to also be spawned on all the client peers too.
	# We add the 'true' argument to force readable names - required by MultiplayerSpawner.
	spawned_players.add_child(player_instance, true)


func spawn_enemy() -> void:
	Log.pr(str(get_tree()) + "Spawning enemy")
	
	var enemy_skeleton_instance = enemy_skeleton_scene.instantiate()
	
	spawned_enemies.add_child(enemy_skeleton_instance, true)
