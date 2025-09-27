extends CharacterBody2D

## The player script - It handles the movement of the player, and applies
## the appropriate animation.
## In this game, the local client peers have "authority" over their player node,
## which means that local players see their character move immediately, without
## any associated "lag" that you get with server-authority.
## The client peers send some of their important information to the server,
## including their position, the player's input, etc, via the attached
## MultiplayerSynchronizer nodes.
## The server is still the "source-of-truth" for the overall state of
## the game. This means that if both you and another peer both appear to 
## collect a "pick-up" at the same time, it will be the server that decies which
## peer really touched it first, and award the "pick-up" to them.

# Pre-loads
var projectile_bullet_scene: PackedScene = preload("res://scenes/projectiles/projectile_bullet.tscn")

# Constants
const SPEED = 30.0
const ACCELERATION = 300.0
const DECELERATION = 300.0

# We gather the player input from this separate script, which can be independently synchronized to the server
#@onready var player_input: Node = $player_input
@export var player_input: PlayerInput

@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer
@onready var peer_id_label: Label = $peer_id_label
@onready var peer_authority_id_label: Label = $peer_authority_id_label
@onready var input_authority_id_label: Label = $input_authority_id_label

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var weapon_pivot: Node2D = $weapon_pivot

@export var peer_id: int = -1

func _ready() -> void:
	# Take a frame to allow the network to synchronize, etc, and let player_id
	# be set.
	# I tried using the _enter_tree() method instead, and it didn't work.
	await get_tree().process_frame
	
	# Ensure that the server/host is the autohority over the player node
	set_multiplayer_authority(1)
	
	# Grant the particular peer_id authority over this player's input node.
	# Netfox uses Server Authority over the player node, but we grant Client
	# Authority to the player_input node.
	player_input.set_multiplayer_authority(peer_id)
	
	# Activate the Rollback Synchronizer's settings
	rollback_synchronizer.process_settings()
	
	# Might need to set the camera appropriately to follow this player - TBD


func _rollback_tick(_delta, _tick, _is_fresh) -> void:
	velocity = player_input.input_direction * SPEED
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor

# Temporary - used to show the player_id, and the id of the authority of the player node
# Helps with debugging who is in charge of which player nodes.
func _process(_delta: float) -> void:
	peer_id_label.text = "id : " + str(peer_id)
	peer_authority_id_label.text = "auth_id : " + str(get_multiplayer_authority())
	input_authority_id_label.text = "input_auth_id : " + str(player_input.get_multiplayer_authority())
	
	weapon_pivot.look_at(position + player_input.aim_direction)
	apply_animation()
	

#func _physics_process(delta: float) -> void:
	## Only allow this player's authority to perform actions
	#if not is_multiplayer_authority():
		#return
	#
	## Use the input direction from player_input node and handle the movement/deceleration.
	#if player_input.input_direction:
		#var target_velocity = SPEED * player_input.input_direction
		#velocity = velocity.move_toward(target_velocity, ACCELERATION * delta)
	#else:
		#velocity = velocity.move_toward(Vector2.ZERO, DECELERATION * delta)
#
	#if player_input.just_fired:
		#var projectile_bullet_instance = projectile_bullet_scene.instantiate()
		#projectile_bullet_instance.position = position
		#projectile_bullet_instance.look_at(position + player_input.aim_direction)
		#get_tree().current_scene.get_node("projectiles").add_child(projectile_bullet_instance)
		#
	#
	#move_and_slide()
	


# Play the appropriate animation based on the player's velocity
func apply_animation() -> void:
	if velocity == Vector2.ZERO:
		animation_player.play("idle")
	else:
		animation_player.play("walk")
