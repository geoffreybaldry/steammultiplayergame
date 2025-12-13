extends CharacterBody2D
class_name Enemy

#@export var speed:float = 10.0
@export var max_speed:float = 10.0
@export var acceleration:float = 300.0
@export var deceleration:float = 300.0
@export var sensor_radius:float = 30.0
@export var min_sensor_radius:float = 10.0
@export var health:float = 3.0

@onready var sprite_2d: Sprite2D = $visual/Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var texture_progress_bar: TextureProgressBar = $visual/TextureProgressBar


func _rollback_tick(_delta, _tick, _is_fresh: bool):
	pass


func _process(_delta: float) -> void:
	pass
	#if Engine.is_editor_hint(): return


func apply_animation() -> void:
	pass
	
	
# Used to reduce the health of the enemy
func damage(_value:float) -> void:
	var tween = get_tree().create_tween()
	tween.tween_method(set_shader_blink_intensity, 1.0, 0.0, 0.5)
	
# Used to perform "push back" on an enemy
func shove(_direction: Vector2, _force: float) -> void:
	pass


func set_shader_blink_intensity(new_value: float) -> void:
	sprite_2d.material.set_shader_parameter("blink_intensity", new_value)
