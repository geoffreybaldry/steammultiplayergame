@tool
extends Area2D
class_name Firebolt

@export var speed:int
@export var damage:int
@export var shove_force:float

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var hurtbox: Area2D = $HurtBox
@onready var hurtbox_collision_shape_2d: CollisionShape2D = $HurtBox/CollisionShape2D
@onready var queue_free_timer: Timer = $queue_free_timer	# Allows time to play sounds before free
@onready var long_lived_timer: Timer = $long_lived_timer	# No projectile should live longer than 5 secs

@onready var predictive_synchronizer: PredictiveSynchronizer = $PredictiveSynchronizer
@onready var tick_interpolator: TickInterpolator = $TickInterpolator

var audio = {
	"impactMetal_002" = preload("res://assets/audio/effects/sci-fi/impactMetal_002.ogg")
}
var fired_by: int
var fired_tick: int
var hit_something: bool = false
var is_disabled: bool = false
var queue_removal: bool = false


func _get_rollback_state_properties() -> Array:
	return [
		"position",
		"hit_something",
		"queue_removal",
	]

func _get_interpolated_properties():
	return [
		"position",
	]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect to NetworkTime signals
	NetworkTime.after_tick_loop.connect(_after_tick_loop)
	
	animation_player.play("firebolt_flying")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
	
func _rollback_tick(_delta, _tk, _is_fresh: bool):
	if is_disabled:
		return
	
	# Check if our hurtbox collided with any hitboxes
	var collisions = hurtbox.get_overlapping_areas()
	if collisions:
		hit_something = true
		for collider in collisions:
			var actor = collider.get_parent()
			if actor.has_method("damage"):
				#Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Sending some damage on tick " + str(NetworkTime.tick) + " and rollback tick " + str(_tk))
				actor.damage(1.0)
				#is_disabled = true
				if actor.has_method("shove"): # If the actor is shovable, then shove them too
					actor.shove(Vector2(1,0).rotated(rotation), shove_force)
				#NetworkRollback.mutate(actor) # Waiting for example to see if we need this
	else:
		hit_something = false

	position += transform.x * speed * _delta


# Processes that happen at the end of a tick loop
func _after_tick_loop():
	if hit_something:
		Log.pr("_after_tick_loop - Did hit someting")
		disable_projectile()


func firing_audio() -> void:
	audio_stream_player_2d.stream = audio.pick_random()
	audio_stream_player_2d.pitch_scale = randf_range(0.8, 1.2)
	audio_stream_player_2d.play()


func disable_projectile() -> void:
	is_disabled = true
	collision_shape_2d.set_deferred("disabled", true)
	hurtbox_collision_shape_2d.set_deferred("disabled", true)
	visible = false
	
	# Disable the rollbacksynchronizer so it stops sending RPCs...
	#rollback_synchronizer.state_properties = []
	#rollback_synchronizer.input_properties = []
	#rollback_synchronizer.process_settings()
	
	# Give some time for the projectile to fully disable
	queue_free_timer.start()
	

func _on_body_entered(_body: Node2D) -> void:
	audio_stream_player_2d.play()
	Log.pr("Firebolt hit body")
	#queue_free()
	#disable_projectile()



func _on_timer_timeout() -> void:
	queue_free()


func _on_long_lived_timer_timeout() -> void:
	disable_projectile()
