extends Area2D
class_name Firebolt

@export var speed:int
@export var damage:int
@export var shove_force:float

@onready var hitbox_collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var hurtbox_collision_shape_2d: CollisionShape2D = $HurtBox/CollisionShape2D
@onready var state_synchronizer: StateSynchronizer = $StateSynchronizer
@onready var tick_interpolator: TickInterpolator = $TickInterpolator


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
