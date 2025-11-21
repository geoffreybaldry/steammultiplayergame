extends Area2D
class_name Projectile

@export var speed:int
@export var damage:int

@onready var timer: Timer = $Timer
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

var fired_by:int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NetworkTime.on_tick.connect(_tick)


func _tick(_delta, _t) -> void:
	pass


func remove_projectile() -> void:
	queue_free()
	NetworkTime.on_tick.disconnect(_tick)
	
	#TBD Implement projectile pooling/reuse
	#TBD Spawn an effect scene now if needed
