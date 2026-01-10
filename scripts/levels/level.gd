extends Node2D
class_name Level

@onready var level_phantom_camera: PhantomCamera2D = $level_phantom_camera

var enemy_start_markers: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Discover any enemy start markers in the level
	enemy_start_markers = get_node("enemy_start_markers").get_children()
		
	if is_multiplayer_authority():
		# Request creation of enemies at the enemy start marker locations
		for enemy_start_marker: Marker2D in enemy_start_markers:
			Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " 
				+ " Requesting enemy spawn of type " 
				+ enemy_start_marker.ENEMY_TYPES.find_key(enemy_start_marker.enemy_type))
			Events.game_events.spawn_enemy_request.emit(enemy_start_marker.enemy_type, enemy_start_marker.global_position)
	
	# Let the Network Server know that we have loaded the level
	Levels.player_loaded.rpc_id(1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
