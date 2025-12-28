extends Node2D
class_name Level

@onready var camera_start_marker: Marker2D = $camera_start_marker
@onready var phantom_camera_2d: PhantomCamera2D = $PhantomCamera2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Grab the camera and center it on the level's start position
	phantom_camera_2d.position = camera_start_marker.position
		
	# Let the Network Server know that we have loaded the level
	Levels.player_loaded.rpc_id(1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
