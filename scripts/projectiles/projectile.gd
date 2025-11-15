extends Area2D
class_name Projectile

@export var speed:int
@export var damage:int

@onready var timer: Timer = $Timer
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

var peer_id:int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	pass


func remove_projectile() -> void:
	queue_free()
	#TBD Implement projectile pooling/reuse
