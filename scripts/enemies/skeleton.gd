extends Enemy
class_name Skeleton


func _ready() -> void:
	super()
	ready_position_label.text = str(global_position)

func _process(delta: float) -> void:
	super(delta)
	state_label.text = str(STATES.keys()[current_state])
	velocity_label.text = str(velocity)
	shove_vector_label.text = str(shove_vector)
	

func _tick(_dt:float, _tk: int):
	super(_dt, _tk)
	if current_state == STATES.DYING:
		return
	
	var nearby_player:= find_nearby_player()
	if nearby_player:
		navigation_agent_2d.set_target_position(nearby_player.global_position)
		current_state = STATES.CHASING


func _rollback_tick(_delta, _tk, _is_fresh: bool):
	super(_delta, _tk, _is_fresh)
	
	if current_state == STATES.DYING:
		return
		
	# Do not query when the map has never synchronized and is empty.
	if NavigationServer2D.map_get_iteration_id(navigation_agent_2d.get_navigation_map()) == 0:
		return
		
	# Apply different movement logic if being shoved Vs chasing, etc
	if apply_shove:
		# Shove navigation logic
		velocity = shove_vector
		_on_velocity_computed(velocity)
		shove_vector = shove_vector.move_toward(Vector2.ZERO, deceleration * _delta)
		if shove_vector.length() < 10:
			shove_vector = Vector2.ZERO
			apply_shove = false
	else:
		if current_state == STATES.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, deceleration * _delta)
			_on_velocity_computed(velocity)
		else:
			# Path navigation logic
			var next_path_position: Vector2 = navigation_agent_2d.get_next_path_position()
			var target_vector: Vector2 = global_position.direction_to(next_path_position).normalized() * max_speed
			velocity = velocity.move_toward(target_vector, acceleration * _delta) 
			
			if navigation_agent_2d.avoidance_enabled:
				navigation_agent_2d.set_velocity(velocity)
			else:
				_on_velocity_computed(velocity)


func _on_velocity_computed(safe_velocity: Vector2):
	super(safe_velocity)
	
	velocity = safe_velocity
	velocity = velocity.limit_length(max_speed)
	
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor


func apply_animation() -> void:
	super()
	match current_state:
		STATES.DYING:
			animation_player.play("skeleton_animations/skeleton_die")
		STATES.IDLE:
			animation_player.play("skeleton_animations/skeleton_idle")
		STATES.CHASING:
			animation_player.play("skeleton_animations/skeleton_walk")
			

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
	

func damage(value:float) -> void:
	super(value)
	
	
# Used to perform "push back" on an enemy
func shove(direction: Vector2, force: float) -> void:
	super(direction, force)


# Used to play out death sequence, and free the object
func die() -> void:
	super()


@rpc("any_peer", "call_local", "reliable")
func disable_entity() -> void:
	Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Disabling RBS on enemy " + str(id))
	rollback_synchronizer.state_properties = []
	rollback_synchronizer.input_properties = []
	rollback_synchronizer.process_settings()
	
	visible = false
	collision_shape_2d.disabled = true
	hitbox_collision_shape_2d.disabled = true
	

# Used when the enemy is fully dead, to clean-up, remove the object, etx.
func dead() -> void:
	super()
