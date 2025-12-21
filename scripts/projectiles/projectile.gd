extends Area2D
class_name Projectile

@export var speed:int
@export var damage:int
@export var shove_force:float

@onready var long_running_timer: Timer = $long_running_timer
@onready var freeing_timer: Timer = $freeing_timer
@onready var projectile_collision_shape_2d: CollisionShape2D = $projectile_collision_shape_2d
@onready var projectile_hurtbox_collision_shape_2d: CollisionShape2D = $HurtBox/projectile_hurtbox_collision_shape_2d
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var tick_interpolator: TickInterpolator = $TickInterpolator

var fired_by:int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NetworkTime.on_tick.connect(_tick)
	audio_stream_player_2d.play()


func _tick(_delta, _t) -> void:
	pass


func disable_projectile() -> void:
	projectile_collision_shape_2d.set_deferred("disabled", true)
	projectile_hurtbox_collision_shape_2d.set_deferred("disabled", true)
	visible = false
	freeing_timer.start()
	

func remove_projectile() -> void:
	queue_free()
	NetworkTime.on_tick.disconnect(_tick)
	
	#TBD Implement projectile pooling/reuse
	#TBD Spawn an effect scene now if needed


# Used to provide enough time for soundeffects, etc to complete, before removal
func _on_freeing_timer_timeout() -> void:
	remove_projectile()

# Used to remove a projectile that has been simply alive for too long
func _on_long_running_timer_timeout() -> void:
	pass # Replace with function body.
