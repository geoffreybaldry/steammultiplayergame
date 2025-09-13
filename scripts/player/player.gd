extends CharacterBody2D

const SPEED = 30.0
const ACCELERATION = 300.0
const DECELERATION = 300.0

func _physics_process(delta: float) -> void:
	
	# Get the input direction and handle the movement/deceleration.
	var input_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction:
		var target_velocity = SPEED * input_direction
		velocity = velocity.move_toward(target_velocity, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, DECELERATION * delta)

		
	move_and_slide()
	Log.pr(str(velocity))
