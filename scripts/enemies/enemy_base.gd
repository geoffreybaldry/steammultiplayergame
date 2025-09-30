extends CharacterBody2D


const SPEED = 50.0

func _ready():
	NetworkTime.on_tick.connect(_tick)


func _tick(dt: float, _t) -> void:
	if not is_multiplayer_authority():
		return
