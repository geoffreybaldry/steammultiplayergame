extends Node2D

const SPAWN_RANDOM: int = 25

var player_scene = preload("res://scenes/player/player.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect to internal signals required by the server
	if multiplayer.is_server():
		SteamNetwork.all_peers_loaded.connect(_on_all_peers_loaded)
		SteamNetwork.peer_disconnected.connect(_on_peer_disconnected)
	
	# If we are a client, we care about disconnecton from the host server, so that we can clean up and return to Main Menu
	SteamNetwork.host_server_disconnected.connect(_on_host_server_disconnected)
	
	# Let the Network know that we have loaded the level
	SteamNetwork.player_loaded.rpc()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	

# Spawn the players into the level - Only the Server does this, the clients 
# get the players spawned automatically through the MultiplayerSpawner.
# In fact, only the server should notice this signal being emitted.
func _on_all_peers_loaded() -> void:
	if not multiplayer.is_server():
		return
		
	# Spawn all the player scenes into the level
	Log.pr("Spawning Players into Level...")
	for this_player in SteamNetwork.players:
		spawn_player(this_player)


func _on_peer_disconnected(this_peer_id: int) -> void:
	despawn_player(this_peer_id)


func _on_host_server_disconnected() -> void:
	Log.pr("Host server disconnected. TBD - Implement game-over and back to Main Menu")
	

func spawn_player(this_id: int) -> void:
	Log.pr("Spawning player with id : " + str(this_id))
	
	# Instantiate a player scene, give it the correct peer id, and grant authority to the client
	var player = player_scene.instantiate()
	
	# Setting this player_id on the player object allows it to be given the correct multiplayer 
	# authority once the player object is added to the scene tree with 
	# $spawned_players.add_child(player, true) at the bottom.
	player.player_id = this_id
	
	# Set the player's position to a random offset from an initial value - replace this with spawn pads later
	var pos: Vector2 = Vector2.from_angle(randf() * 2 * PI)
	player.position = Vector2(50, 120) + Vector2(pos.x * SPAWN_RANDOM * randf(), pos.y * SPAWN_RANDOM * randf())
	
	# Add the player instance to the scene tree, under the MultiplayerSpawner's spawn path.
	# This causes the instance to also be spawned on all the client peers too.
	# We add the 'true' argument to force readable names - required by multiplayer.
	$spawned_players.add_child(player, true)
	


func despawn_player(this_id: int) -> void:
	Log.pr("Despawning player with id : " + str(this_id))
	# TBD - despawn the player - done on server only, I guess, but need to react to it on client
	
	
# Is this really needed?
#func _exit_tree() -> void:
	## Disconnect signals
	#SteamNetwork.all_peers_loaded.disconnect(_on_all_peers_loaded)
	#SteamNetwork.host_server_disconnected.disconnect(_on_host_server_disconnected)
	#SteamNetwork.peer_disconnected.disconnect(_on_peer_disconnected)
