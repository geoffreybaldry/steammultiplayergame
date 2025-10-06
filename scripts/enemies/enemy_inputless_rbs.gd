@tool
extends CharacterBody2D

const SPEED = 10.0
const ACCELERATION = 300.0
const DECELERATION = 300.0
const SENSOR_RADIUS = 30.0
const MIN_RADIUS = 10.0
#
#@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer

@onready var auth_id_label: Label = $auth_id_label
@onready var nearby_player_label: Label = $nearby_player_label
@onready var target_motion_label: Label = $target_motion_label

var target_motion: Vector2 = Vector2.ZERO

#func _ready() -> void:
	#if Engine.is_editor_hint(): return
	#rollback_synchronizer.process_settings()
	
	
func _get_rollback_state_properties() -> Array:
	return [
		"position",
		"velocity"
	]

func _get_interpolated_properties() -> Array:
	return [
		"position"
	]

	
func _rollback_tick(_delta, _tick, _is_fresh: bool):
	auth_id_label.text = "auth id : " + str(get_multiplayer_authority())
	nearby_player_label.text = "nearby player : n/a"
	target_motion_label.text = "target motion : n/a"
	
	#var target_motion := Vector2.ZERO
	target_motion = Vector2.ZERO
	var nearby_player := _find_nearby_player()
	
	# Check if we are near a player
	if nearby_player:
		nearby_player_label.text = "nearby player : " + nearby_player.name
		
		# Calculate difference as vector
		target_motion = nearby_player.global_position - global_position

		target_motion_label.text = "target motion : " + str(target_motion)
		
		# Set the desired target vector
		target_motion = target_motion.normalized() * SPEED
		
			
		# Set desired velocity towards target
		#velocity = velocity.move_toward(target_motion, ACCELERATION * delta)
		#velocity.x = move_toward(velocity.x, target_motion.x, SPEED / 0.35 * delta)
		#velocity.y = move_toward(velocity.y, target_motion.y, SPEED / 0.35 * delta)
		velocity.x = target_motion.x
		velocity.y = target_motion.y
	else:
		## Set desired velocity to zero
		#pass
		##velocity = velocity.move_toward(Vector2.ZERO, DECELERATION * delta)
		velocity = Vector2.ZERO
	
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor


func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	#apply_animation()
	auth_id_label.text = "auth id : " + str(get_multiplayer_authority())
	
	
#func apply_animation() -> void:
	#if velocity == Vector2.ZERO:
		#animation_player.play("idle")
	#else:
		#animation_player.play("walk")
		

func _find_nearby_player() -> Node2D:
	var players := get_tree().get_nodes_in_group(&"Players")
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
