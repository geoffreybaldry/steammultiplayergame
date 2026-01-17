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
@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer
@onready var tick_interpolator: TickInterpolator = $TickInterpolator
@onready var hurt_box: Area2D = $HurtBox

var fired_by: int
var is_disabled: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NetworkTime.after_tick_loop.connect(_after_tick_loop)
	audio_stream_player_2d.play()
	

func _tick(_delta, _t) -> void:
	pass


func _rollback_tick(_delta, _tk, _is_fresh: bool):
	pass


func _after_tick_loop():
	pass
	

func disable_projectile() -> void:
	#Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Disabling projectile")
	#Events.error_messages.error_message.emit("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Disabling projectile", 3)
	projectile_collision_shape_2d.set_deferred("disabled", true)
	projectile_hurtbox_collision_shape_2d.set_deferred("disabled", true)
	visible = false
	
	# Disable the rollbacksynchronizer so it stops sending RPCs...
	rollback_synchronizer.state_properties = []
	rollback_synchronizer.input_properties = []
	rollback_synchronizer.process_settings()
	
	freeing_timer.start()
	

func remove_projectile() -> void:
	queue_free()
	
	#TBD Implement projectile pooling/reuse
	#TBD Spawn an effect scene now if needed


# Used to provide enough time for soundeffects, etc to complete, before removal
func _on_freeing_timer_timeout() -> void:
	remove_projectile()

# Used to remove a projectile that has been simply alive for too long
func _on_long_running_timer_timeout() -> void:
	pass # Replace with function body.
