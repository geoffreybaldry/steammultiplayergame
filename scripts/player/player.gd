extends CharacterBody2D

const SPEED = 30.0
const ACCELERATION = 300.0
const DECELERATION = 300.0

# We gather the player input from this separate script, which can be independently synchronized to the server
@onready var player_input: Node = $player_input

@onready var player_id_label: Label = $player_id_label
@onready var authority_id_label: Label = $authority_id_label

# Exporting this var makes it easily selectable in the MultiplayerSynchronizer
@export var player_id: int = -1


# _enter_tree() happens at the moment this object is added to the scene tree via
# something calling add_child(this_object, true). In our case the level itself
# instantiates the player, and sets its player_id before doing the add_child.
#func _enter_tree() -> void:
	## Grant the particular player_id authority over this player node.
	## This means we are doing "Client Authority", meaning that the client "owns"
	## or "is the authority" over this player node in the scene tree.
	#set_multiplayer_authority(player_id)


func _ready() -> void:
	await get_tree().process_frame
	set_multiplayer_authority(player_id)
	#pass
	# Might need to set the camera appropriately to follow this player - TBD


# Temporary - used to show the player_id, and the id of the authority of the player node
# Helps with debugging who is in charge of which player nodes.
func _process(_delta: float) -> void:
	player_id_label.text = "id : " + str(player_id)
	authority_id_label.text = "auth_id : " + str(get_multiplayer_authority())


func _physics_process(delta: float) -> void:
	# Only allow this player's authority to perform actions
	if not is_multiplayer_authority():
		return
	
	# Use the input direction from player_input node and handle the movement/deceleration.
	if player_input.input_direction:
		var target_velocity = SPEED * player_input.input_direction
		velocity = velocity.move_toward(target_velocity, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, DECELERATION * delta)

	move_and_slide()
