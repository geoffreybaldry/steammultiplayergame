@tool
extends CharacterBody2D
class_name Skeleton

@export var max_speed: float = 40.0
@export var acceleration: float = 30.0
@export var deceleration: float = 30.0
@export var max_health: float = 6.0
@export var attack_range: float = 25.0

@export var state_machine: RewindableStateMachine

# Collisions
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hit_box: Area2D = $HitBox
@onready var hitbox_collision_shape_2d: CollisionShape2D = $HitBox/CollisionShape2D
@onready var hurt_box: Area2D = $HurtBox
@onready var hurtbox_collision_shape_2d: CollisionShape2D = $HurtBox/CollisionShape2D
@onready var player_detector: Area2D = $PlayerDetector
@onready var player_detector_collision_shape_2d: CollisionShape2D = $PlayerDetector/CollisionShape2D

# Visual
@onready var sprite_2d: Sprite2D = $visual/Sprite2D
@onready var healthbar: TextureProgressBar = $visual/healthbar
@onready var state_label: Label = $visual/VBoxContainer/state_label
@onready var health_label: Label = $visual/VBoxContainer/health_label

# Audio
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

# Nav
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D

var id: String
var health: float : 
	set(value) :
		var old_value = health
		health = value
		if old_value != value:
			Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "health : " + str(health))
		
var shove_vector: Vector2
var is_dying: bool = false



var audio = {
	"impactMetal_002" = preload("res://assets/audio/effects/sci-fi/impactMetal_002.ogg")
}


func _get_interpolated_properties():
	return ["position"]


func _get_rollback_state_properties() -> Array:
	return [
		"position",
		"health",
		["RewindableStateMachine", "state"],
	]

func _ready() -> void:
	NetworkTime.on_tick.connect(_tick)
	NetworkTime.after_tick_loop.connect(_after_tick_loop)
	
	navigation_agent_2d.velocity_computed.connect(Callable(_on_velocity_computed))
	
	# The server must own the enemies
	set_multiplayer_authority(1)
	
	# Set starting health
	health = max_health
	
	# Set starting state
	state_machine.state = &"IDLE"
	
	
func _tick(_dt:float, _tk: int):
	pass


func _rollback_tick(_delta, _tk, _is_fresh: bool):
	# Handle the "shoving" centrally here, as it applies to all states
	if shove_vector:
		velocity = shove_vector # Shoving over-rides any existing velocity
		_on_velocity_computed(velocity)
		# Diminish the shove vector over time
		shove_vector = shove_vector.move_toward(Vector2.ZERO, deceleration)
		if shove_vector.length() < 5:
			shove_vector = Vector2.ZERO
	

func _after_tick_loop() -> void:
	health_label.text = str(health)
	healthbar.value = (health / max_health) * 100
	
	if health <= 0:
		is_dying = true
	

func find_nearby_player() -> Node2D:
	var closest_player: Node2D = null
	var closest_distance = INF
	var players = player_detector.get_overlapping_bodies()
	
	for player in players:
		# Check if the player is in sight by casting a ray at them; discard if not
		if is_in_sight(player):
			var distance_to_player = global_position.distance_to(player.global_position)
			if distance_to_player < closest_distance:
				closest_distance = distance_to_player
				closest_player = player
	
	return closest_player


# Cast a ray at the player to check if we can see them
func is_in_sight(player: Node2D) -> bool:
	ray_cast_2d.target_position = player.global_position - position
	var collider = ray_cast_2d.get_collider()
	if collider and collider.is_in_group("Players"):
		return true
		
	return false


func set_movement_target(movement_target: Vector2):
	navigation_agent_2d.set_target_position(movement_target)


# Used to make the enemy blink when hit
func set_shader_blink_intensity(new_value: float) -> void:
	sprite_2d.material.set_shader_parameter("blink_intensity", new_value)
	
	
func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	velocity = velocity.limit_length(max_speed)
	velocity *= NetworkTime.physics_factor
	# move_and_slide assumes physics delta
	move_and_slide()
	velocity /= NetworkTime.physics_factor

# Used to reduce the health of the enemy
func damage(value:int) -> void:
	Events.error_messages.error_message.emit("Damage!!!", 2)
	health -= value
	
	# Blink the enemy
	var tween = get_tree().create_tween()
	tween.tween_method(set_shader_blink_intensity, 1.0, 0.0, 0.25)
	
	# Play impact/pain sounds
	audio_stream_player_2d.play()

# Used to perform "push back" on an enemy
func shove(direction: Vector2, force: float) -> void:
	shove_vector = direction * force
	
	
# Used to play out death sequence, sounds, etc.
func die() -> void:
	pass


# Used when the enemy is fully dead, to clean-up, remove the object, etc.
func dead() -> void:
	# Disconnect signals
	#NetworkTime.on_tick.disconnect(_tick)
	#navigation_agent_2d.velocity_computed.disconnect(Callable(_on_velocity_computed))
	
	if is_multiplayer_authority():
		Events.game_events.enemy_died.emit(id)
