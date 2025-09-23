extends Node2D

# Temporary help in stopping players spawning on top of eachother
const SPAWN_RANDOM: int = 25

var player_scene = preload("res://scenes/player/player.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect to signals
	if multiplayer.is_server():
		SteamNetwork.all_peers_loaded.connect(_on_all_peers_loaded)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass


# This function is called when all the peers have successfully loaded the
# level - it creates the player objects on the server peer, and allows the
# MultiplayerSpawner to then replicate them across the client peers.
func _on_all_peers_loaded() -> void:
	Log.pr("Spawning Players into Level...")
	for this_player in SteamNetwork.players:
		spawn_player(this_player)


# This function only happens on the server - the MultiplayerSpawner replicates 
# any spawned player nodes on all the peer clients.
func spawn_player(this_id: int) -> void:
	Log.pr("Spawning player with id : " + str(this_id))
	
	# Instantiate a player scene, give it the correct peer id, and grant authority to the client
	var player_instance = player_scene.instantiate()
	
	# Setting this player_id on the player object allows it to be given the correct multiplayer 
	# authority once the player object is added to the scene tree with 
	# $spawned_players.add_child(player, true).
	player_instance.player_id = this_id
	
	# This makes the player node in the scene tree have the player's id as its name
	# Useful for debugging in the "remote" scene view, and also for later despawning if necessary
	player_instance.name = str(this_id) 
	
	# Set the player's position to a random offset from an initial value - replace this with spawn pads later
	var pos: Vector2 = Vector2.from_angle(randf() * 2 * PI)
	player_instance.position = Vector2(50, 120) + Vector2(pos.x * SPAWN_RANDOM * randf(), pos.y * SPAWN_RANDOM * randf())
	
	# Add the player instance to the scene tree, under the MultiplayerSpawner's spawn path.
	# This causes the instance to also be spawned on all the client peers too.
	# We add the 'true' argument to force readable names - required by MultiplayerSpawner.
	$spawned_players.add_child(player_instance, true)


# If for any reason we need to remove a peer's player, then the server will despawn it, and it
# will cause it to be removed on all the peers too.
#func despawn_player(this_id: int) -> void:
	#Log.pr("Despawning player with id : " + str(this_id))
	#$spawned_players.get_node(str(this_id)).queue_free()
		#
	## TBD - despawn the player - done on server only, I guess, but need to react to it on client
