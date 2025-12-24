extends CharacterBody2D
class_name Enemy

@export var max_speed: float = 10.0
@export var acceleration: float = 300.0
@export var deceleration: float = 300.0
@export var sensor_radius: float = 30.0
@export var min_sensor_radius: float = 10.0
@export var max_health: float

@onready var navigation_agent_2d: NavigationAgent2D = $navigation/NavigationAgent2D
@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer
@onready var tick_interpolator: TickInterpolator = $TickInterpolator
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

@onready var sprite_2d: Sprite2D = $visual/Sprite2D
@onready var animation_player: AnimationPlayer = $visual/AnimationPlayer
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $audio/AudioStreamPlayer2D
@onready var healthbar: TextureProgressBar = $visual/healthbar
@onready var state_label: Label = $visual/state_label
@onready var velocity_label: Label = $visual/velocity_label
@onready var shove_vector_label: Label = $visual/shove_vector_label
@onready var ready_position_label: Label = $visual/ready_position_label

enum STATES {
	IDLE,
	SEARCHIG,
	CHASING,
	ATTACKING,
	DYING,
}

var current_state = STATES.IDLE		# Synchronized
var health: float					# Synchronized
var apply_shove: bool = false
var shove_vector: Vector2

var audio = {
	"impactMetal_002" = preload("res://assets/audio/effects/sci-fi/impactMetal_002.ogg")
}

func _ready() -> void:
	# The server must own the enemies
	set_multiplayer_authority(1)
	
	health = max_health
	
	NetworkTime.on_tick.connect(_tick)
	
	# React to changes in synchronized values
	multiplayer_synchronizer.synchronized.connect(_on_multiplayer_synchronizer_synchronized)
	multiplayer_synchronizer.delta_synchronized.connect(_on_multiplayer_synchronizer_synchronized)
	
	navigation_agent_2d.velocity_computed.connect(Callable(_on_velocity_computed))


func _process(_delta: float) -> void:
	apply_animation()


func _tick(_dt:float, _tk: int):
	pass


func _rollback_tick(_delta, _tk, _is_fresh: bool):
	pass


func _on_multiplayer_synchronizer_synchronized() -> void:
	healthbar.value = (health / max_health) * 100


func set_movement_target(movement_target: Vector2):
	navigation_agent_2d.set_target_position(movement_target)


func apply_animation() -> void:
	pass
	
	
# Used to reduce the health of the enemy
func damage(value:float) -> void:
	# Blink the enemy
	var tween = get_tree().create_tween()
	tween.tween_method(set_shader_blink_intensity, 1.0, 0.0, 0.25)
	
	# Play impact/pain sounds
	audio_stream_player_2d.play()
	
	# Update health, which is server authoratitive
	if is_multiplayer_authority():
		health -= value
		healthbar.value = (health / max_health) * 100
		
		if health <= 0:
			die()
	
	
# Used to perform "push back" on an enemy
func shove(direction: Vector2, force: float) -> void:
	apply_shove = true
	shove_vector = direction * force


# Used to make the enemy blink when hit
func set_shader_blink_intensity(new_value: float) -> void:
	sprite_2d.material.set_shader_parameter("blink_intensity", new_value)


# Used to play out death sequence, sounds, etc.
func die() -> void:
	if is_multiplayer_authority():
		Log.pr("State is DYING")
		current_state = STATES.DYING


# Used when the enemy is fully dead, to clean-up, remove the object, etc.
func dead() -> void:
	# Disconnect signals
	multiplayer_synchronizer.synchronized.disconnect(_on_multiplayer_synchronizer_synchronized)
	multiplayer_synchronizer.delta_synchronized.disconnect(_on_multiplayer_synchronizer_synchronized)
	NetworkTime.on_tick.disconnect(_tick)
	navigation_agent_2d.velocity_computed.disconnect(Callable(_on_velocity_computed))
	
	if is_multiplayer_authority():
		queue_free()


func _on_velocity_computed(_safe_velocity: Vector2):
	pass

func _on_navigation_agent_2d_navigation_finished() -> void:
	current_state = STATES.IDLE
