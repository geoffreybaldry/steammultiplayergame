@tool
extends CharacterBody2D
class_name Skeleton

@export var max_speed: float = 40.0
@export var acceleration: float = 100.0
@export var deceleration: float = 200.0
@export var sensor_radius: float = 120.0
@export var min_sensor_radius: float = 20.0
@export var attack_range:float = 25.0
@export var max_health: float = 6.0

@export var state_machine: RewindableStateMachine

# Collisions
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hitbox_collision_shape_2d: CollisionShape2D = $HitBox/CollisionShape2D

# Visual
@onready var sprite_2d: Sprite2D = $visual/Sprite2D
@onready var healthbar: TextureProgressBar = $visual/healthbar
@onready var animation_player: AnimationPlayer = $visual/AnimationPlayer
@onready var state_label: Label = $visual/VBoxContainer/state_label
@onready var health_label: Label = $visual/VBoxContainer/health_label

# Audio
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

# Nav
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

var id: String
var health: float


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
	NetworkTime.before_tick_loop.connect(_before_tick_loop)
	NetworkTime.on_tick.connect(_tick)
	NetworkTime.after_tick_loop.connect(_after_tick_loop)
	
	navigation_agent_2d.velocity_computed.connect(Callable(_on_velocity_computed))
	
	# The server must own the enemies
	set_multiplayer_authority(1)
	
	# Set starting health
	health = max_health
	
	# Set starting state
	state_machine.state = &"IDLE"
	
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	health_label.text = str(health)
	state_label.text = state_machine.state
	

# Processes that happen before the tick loop
func _before_tick_loop():
	pass
	
	
func _tick(_dt:float, _tk: int):
	pass


func _rollback_tick(_delta, _tk, _is_fresh: bool):
	pass
	

func _after_tick_loop() -> void:
	healthbar.value = (health / max_health) * 100
	
	if health <= 0:
		die()
	

func find_nearby_player() -> Node2D:
	# Escape check in case this node is being freed from the scene tree
	if not is_inside_tree():
		return
	
	var players := get_tree().get_nodes_in_group(&"Players")
	if players.is_empty():
		return null
		
	var sensor_radius_squared := pow(sensor_radius, 2.0)
	var min_radius_squared := pow(min_sensor_radius, 2.0)

	var closest_player: Node2D = null
	var closest_distance := INF
	for player in players:
		var distance := global_position.distance_squared_to(player.global_position)

		if distance >= sensor_radius_squared or distance <= min_radius_squared:
			continue

		if distance < closest_distance:
			closest_distance = distance
			closest_player = player

	return closest_player


func set_movement_target(movement_target: Vector2):
	navigation_agent_2d.set_target_position(movement_target)


# Used to make the enemy blink when hit
func set_shader_blink_intensity(new_value: float) -> void:
	sprite_2d.material.set_shader_parameter("blink_intensity", new_value)
	
	
func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	velocity = velocity.limit_length(max_speed)
	
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor


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

#func _on_navigation_agent_2d_navigation_finished() -> void:
	#Log.pr("Nav finished")
	#pass # Replace with function body.
