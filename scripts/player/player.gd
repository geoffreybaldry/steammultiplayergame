extends CharacterBody2D

## The player script - It handles the movement of the player, and applies
## the appropriate animation, etc.
##
## This game uses NetFox for Client-Side prediction and Server Reconciliation.
## That's why the player input is separated from the player object. It's so
## we can allow the local player/peer to have ownership of their player_input
## node, but still have the sever/host own the overall player object.
## The player object has a RollbackSynchronizer, which allows certain 'state'
## to be lag-compensated, such as position.

# Constants
const SPEED = 30.0
const ACCELERATION = 300.0
const DECELERATION = 300.0

# We gather the player input from this separate script, which can be independently synchronized to the server
@export var player_input: PlayerInput
# This peer_id gets synchronized by a MultiplayerSynchronizer, only on change
@export var peer_id: int = -1

@export var bullet_scene: PackedScene

@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer
@onready var peer_id_label: Label = $visual/peer_id_label
@onready var peer_authority_id_label: Label = $visual/peer_authority_id_label
@onready var input_authority_id_label: Label = $visual/input_authority_id_label
@onready var animation_player: AnimationPlayer = $visual/AnimationPlayer
@onready var weapon_pivot: Node2D = $visual/weapon_pivot

func _ready() -> void:
	# Take a frame to allow the network to synchronize, etc, and let peer_id
	# be set.
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
	
	weapon_pivot.look_at(position + player_input.aim_direction)
	check_fired()

func _process(_delta: float) -> void:
	# Temporary - used to show the player_id, and the id of the authority of the player node
	# Helps with debugging who is in charge of which player nodes.
	#peer_id_label.text = "id : " + str(peer_id)
	#peer_authority_id_label.text = "auth_id : " + str(get_multiplayer_authority())
	#input_authority_id_label.text = "input_auth_id : " + str(player_input.get_multiplayer_authority())
	
	apply_animation()

# Play the appropriate animation based on the player's velocity
func apply_animation() -> void:
	if velocity == Vector2.ZERO:
		animation_player.play("idle")
	else:
		animation_player.play("walk")


func check_fired() -> void:
	if player_input.just_fired:
		Events.game_events.player_fired.emit(peer_id, global_position, weapon_pivot.rotation)
