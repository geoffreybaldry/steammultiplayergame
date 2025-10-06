extends CharacterBody2D


const SPEED = 10.0
const ACCELERATION = 300.0
const DECELERATION = 300.0
const SENSOR_RADIUS = 30.0
const MIN_RADIUS = 10.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	NetworkTime.on_tick.connect(_tick)
	
	
func _tick(delta, _t) -> void:
	var target_motion := Vector2.ZERO
	var nearby_player := _find_nearby_player()
	
	# Check if we are near a player
	if nearby_player:
		# Calculate difference as vector
		target_motion = nearby_player.global_position - global_position

		# Set the desired target vector
		target_motion = target_motion.normalized() * SPEED
	
		# Set desired velocity towards target
		velocity = velocity.move_toward(target_motion, ACCELERATION * delta)
	else:
		# Set desired velocity to zero
		velocity = velocity.move_toward(Vector2.ZERO, DECELERATION * delta)
	
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor


func _process(_delta: float) -> void:
	apply_animation()
	
	
func apply_animation() -> void:
	if velocity == Vector2.ZERO:
		animation_player.play("skeleton_animations/idle")
	else:
		animation_player.play("skeleton_animations/walk")
		

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
