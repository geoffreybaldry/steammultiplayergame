@tool
extends CharacterBody2D

const SPEED = 10.0
const ACCELERATION = 300.0
const DECELERATION = 300.0
const SENSOR_RADIUS = 20.0
const MIN_RADIUS = 5.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer
@onready var hit_box: Area2D = $hit_box

var health: int = 4

func _ready():
	# Activate the Rollback Synchronizer's settings
	rollback_synchronizer.process_settings()
	
	if is_multiplayer_authority():
		hit_box.area_entered.connect(_on_hit_box_area_entered)


func _rollback_tick(_delta, _tick, _is_fresh) -> void:
	var target_motion := Vector2.ZERO
	var nearby_player := _find_nearby_player()
	
	# Check if we are near a player
	if nearby_player:
		# Calculate difference as vector
		target_motion = nearby_player.global_position - global_position

		# Set the desired target vector
		target_motion = target_motion.normalized() * SPEED
	
		# Set desired velocity towards target
		velocity = velocity.move_toward(target_motion, ACCELERATION * _delta)
	else:
		# Set desired velocity to zero
		velocity = velocity.move_toward(Vector2.ZERO, DECELERATION * _delta)
	
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor


func _process(delta: float) -> void:
	apply_animation()
	
	
func apply_animation() -> void:
	if velocity == Vector2.ZERO:
		animation_player.play("idle")
	else:
		animation_player.play("walk")
		

func _find_nearby_player() -> Node2D:
	var players := get_tree().get_nodes_in_group(&"players")
	if players.is_empty():
		return null
		
	var sensor_radius_squared := pow(SENSOR_RADIUS, 2.0)
	var min_radius_squared := pow(MIN_RADIUS, 2.0)

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


func _get_rollback_state_properties() -> Array:
	return [
		"position",
		"velocity"
	]


func _get_interpolated_properties() -> Array:
	return [
		"position"
	]


func _on_hit_box_area_entered(area: Area2D) -> void:
	Log.pr("My hit-box was entered!")
