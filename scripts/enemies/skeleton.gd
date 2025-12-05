@tool
extends Enemy
class_name Skeleton

var target_vector: Vector2 = Vector2.ZERO

func _rollback_tick(delta, _tick, _is_fresh: bool):
	target_vector = Vector2.ZERO
	var nearby_player := find_nearby_player()
	
	# Check if we are near a player
	if nearby_player:
		#nearby_player_label.text = "nearby player : " + nearby_player.name
		
		# Calculate difference as vector
		target_vector = nearby_player.global_position - global_position
		
		# Set the desired target vector
		target_vector = target_vector.normalized() * speed
		
		# Set desired velocity towards target
		velocity = velocity.move_toward(target_vector, acceleration * delta)
	else:
		## Set desired velocity to zero
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor
	
	
func _process(delta: float) -> void:
	super(delta)
	apply_animation()
	

func apply_animation() -> void:
	if velocity == Vector2.ZERO:
		animation_player.play("skeleton_animations/skeleton_idle")
	else:
		animation_player.play("skeleton_animations/skeleton_walk")
		
		
func find_nearby_player() -> Node2D:
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

	
