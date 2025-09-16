extends CharacterBody2D

const SPEED = 30.0
const ACCELERATION = 300.0
const DECELERATION = 300.0

# We gather the player input from this separate script, which can be independently synchronized to the server
@onready var player_input: Node = $player_input

@onready var player_id_label: Label = $player_id_label
@onready var authority_id_label: Label = $authority_id_label


@export var player_id: int = -1:
	set(value):
		player_id = value
		$PlayerInputSynchronizer.set_multiplayer_authority(player_id)
	get:
		return player_id


func _ready() -> void:
	# Might need to se the camera appropriately to follow this player - TBD
	pass


func _process(delta: float) -> void:
	player_id_label.text = "id : " + str(player_id)
	authority_id_label.text = "auth_id : " + str(get_multiplayer_authority())


func _physics_process(delta: float) -> void:
	# Only allow this player's authority to perform actions
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	
	# Get the input direction and handle the movement/deceleration.
	var input_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction:
		var target_velocity = SPEED * input_direction
		velocity = velocity.move_toward(target_velocity, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, DECELERATION * delta)

	move_and_slide()
