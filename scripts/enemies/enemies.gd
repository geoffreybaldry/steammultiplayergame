extends Node2D

var enemy_scene = preload("res://scenes/enemies/enemy_base.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect to signals
	if multiplayer.is_server():
		SteamNetwork.all_peers_loaded.connect(_on_all_peers_loaded)
		

func _on_all_peers_loaded() -> void:
	Log.pr("Spawning Enemies into Level...")
	
	spawn_enemy()
	
func spawn_enemy() -> void:
	Log.pr("Spawning enemy")
	
	var enemy_instance = enemy_scene.instantiate()
	#player_instance.peer_id = this_peer_id
	
	# This makes the player node in the scene tree have the player's id as its name
	# Useful for debugging in the "remote" scene view, and also for later despawning if necessary
	#enemy_instance.name = str(this_peer_id) 
	
	# Set the player's position to a random offset from an initial value - replace this with spawn pads later
	#var pos: Vector2 = Vector2.from_angle(randf() * 2 * PI)
	#player_instance.position = Vector2(50, 120) + Vector2(pos.x * SPAWN_RANDOM * randf(), pos.y * SPAWN_RANDOM * randf())
	enemy_instance.position = Vector2(50, 80)
	
	
	# Add the player instance to the scene tree, under the MultiplayerSpawner's spawn path.
	# This causes the instance to also be spawned on all the client peers too.
	# We add the 'true' argument to force readable names - required by MultiplayerSpawner.
	$spawned_enemies.add_child(enemy_instance, true)
