extends Node2D

var enemy_state_replicate_scene = preload("res://scenes/enemies/enemy_state_replicate.tscn")
var enemy_inputless_rbs_scene = preload("res://scenes/enemies/enemy_inputless_rbs.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect to signals
	if multiplayer.is_server():
		Network.all_peers_loaded.connect(_on_all_peers_loaded)
		

func _on_all_peers_loaded() -> void:
	Log.pr("Spawning Enemies into Level...")
	
	#spawn_enemy()
	
func spawn_enemy() -> void:
	Log.pr(str(get_tree()) + "Spawning enemy")
	
	#var enemy_instance = enemy_state_replicate_scene.instantiate()
	var enemy_instance = enemy_inputless_rbs_scene.instantiate()
	
	enemy_instance.position = Vector2(50, 80)
	
	$spawned_enemies.add_child(enemy_instance, true)
