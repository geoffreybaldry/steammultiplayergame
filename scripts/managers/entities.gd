extends Node

@export var player_scene: PackedScene
@export var enemy_skeleton_scene: PackedScene

@onready var spawned_players: Node = $spawned_players
@onready var spawned_enemies: Node = $spawned_enemies


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Levels.all_peers_loaded.connect(_on_all_peers_loaded)



# This function is called when all the peers have successfully loaded the
# level - it creates the player objects on the server peer, and allows the
# MultiplayerSpawner to then replicate them across the client peers.
func _on_all_peers_loaded() -> void:
	Log.pr(str(get_tree()) + "Spawning Players into Level...")
	
	for this_player in Network.players:
		# Spread out the initial spawning, to give the spawn points time to recognize if they are occupied
		#await get_tree().create_timer(1.0).timeout
		spawn_player(this_player)
		
	Log.pr(str(get_tree()) + "Spawning Enemies into Level...")
	spawn_enemy()
	
	

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
	
	# Set the player's position to a random offst from an initial value - replace this with spawn pads later
	#var pos: Vector2 = Vector2.from_angle(randf() * 2 * PI)
	#player_instance.position = Vector2(50, 120) + Vector2(pos.x * SPAWN_RANDOM * randf(), pos.y * SPAWN_RANDOM * randf())
	
	# Add the player instance to the scene tree, under the MultiplayerSpawner's spawn path.
	# This causes the instance to also be spawned on all the client peers too.
	# We add the 'true' argument to force readable names - required by MultiplayerSpawner.
	spawned_players.add_child(player_instance, true)


func spawn_enemy() -> void:
	Log.pr(str(get_tree()) + "Spawning enemy")
	var enemy_skeleton_instance = enemy_skeleton_scene.instantiate()
	enemy_skeleton_instance.global_position = Vector2(30, 30)
	spawned_enemies.add_child(enemy_skeleton_instance, true)
