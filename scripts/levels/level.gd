extends Node2D
class_name Level

@onready var camera_start_marker: Marker2D = $camera_start_marker
@onready var phantom_camera_2d: PhantomCamera2D = $PhantomCamera2D

var enemy_start_markers: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Grab the camera and center it on the level's start position
	phantom_camera_2d.position = camera_start_marker.position
		
	# Let the Network Server know that we have loaded the level
	Levels.player_loaded.rpc_id(1)
	
	if is_multiplayer_authority():
		# Discover any enemy start markers in the level
		enemy_start_markers = get_node("enemy_start_markers").get_children()
		
		# Request creation of enemies at these location
		for enemy_start_marker: Marker2D in enemy_start_markers:
			Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " 
				+ " Requesting enemy spawn of type " 
				+ enemy_start_marker.ENEMY_TYPES.find_key(enemy_start_marker.enemy_type))
			Events.game_events.spawn_enemy_request.emit(enemy_start_marker.enemy_type, enemy_start_marker.global_position)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
