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

@export var speed = 30.0
@export var acceleration = 300.0
@export var deceleration = 300.0

# We gather the player input from this separate script, which can be independently synchronized to the server
@onready var player_input: PlayerInput = $player_input

# This peer_id gets synchronized by a MultiplayerSynchronizer, only on change
@export var peer_id: int = -1

@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer
@onready var tick_interpolator: TickInterpolator = $TickInterpolator
@onready var peer_id_label: Label = $visual/peer_id_label
@onready var peer_authority_id_label: Label = $visual/peer_authority_id_label
@onready var input_authority_id_label: Label = $visual/input_authority_id_label
@onready var animation_player: AnimationPlayer = $visual/AnimationPlayer
@onready var weapon_pivot: Node2D = $weapon_pivot

var health: int = 100
var death_tick: int = -1
var did_respawn := false
var respawn_tick: int = -1
var respawn_position: Vector2

func _ready() -> void:
	# Take a frame to allow the network to synchronize, etc, and let peer_id
	# be set.
	await get_tree().process_frame
	
	# Ensure that the server/host is the authority over the player node
	set_multiplayer_authority(1)
	
	# Grant the particular peer_id authority over this player's input node.
	# Netfox uses Server Authority over the player node, but we grant Client
	# Authority to the player_input node.
	player_input.set_multiplayer_authority(peer_id)
	
	# Activate the Rollback Synchronizer's settings - is this needed?
	#rollback_synchronizer.process_settings()
	
	NetworkTime.on_tick.connect(_tick)
	#NetworkTime.after_tick_loop.connect(_after_tick_loop)
	
	respawn_tick = NetworkTime.tick + 100 # Some time in the very near future
	# Might need to set the camera appropriately to follow this player - TBD


@warning_ignore("unused_parameter")
func _tick(_dt:float, tick: int):
	## Check for (re)spawn
	#if tick == respawn_tick:
		#if is_multiplayer_authority():
			#global_position = respawn_position
			#Log.pr("Teleporting " + str(peer_id) + " to global_position " + str(respawn_position))
			#tick_interpolator.teleport()
	
	# Check health
	if health <= 0:
		Log.pr("Player died")


#func _after_tick_loop():
	#if did_respawn:
		#Log.pr(str(multiplayer.get_unique_id()) +  " teleporting")
		#tick_interpolator.teleport()
		
		
func _rollback_tick(_delta, tick, _is_fresh) -> void:
	# Handle respawn
	#if tick == death_tick:
		##global_position = Vector2.ZERO
		#did_respawn = true
	#else:
		#did_respawn = false
		
	# Check for (re)spawn
	if tick == respawn_tick:
		if is_multiplayer_authority():
			global_position = respawn_position
			Log.pr("Teleporting " + str(peer_id) + " to global_position " + str(respawn_position))
			tick_interpolator.teleport()
	
	velocity = player_input.input_direction * speed
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor
	
	weapon_pivot.look_at(position + player_input.aim_direction)
	

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


func die()-> void:
	#respawn_position = get_some_position()
	death_tick = NetworkTime.tick
	
