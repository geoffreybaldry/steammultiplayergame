extends CharacterBody2D
class_name Player
## The player script - It handles the movement of the player, and applies
## the appropriate animation, etc.
##
## This game uses NetFox for Client-Side prediction and Server Reconciliation.
## That's why the player input is separated from the player object. It's so
## we can allow the local player/peer to have ownership of their player_input
## node, but still have the sever/host own the overall player object.
## The player object has a RollbackSynchronizer, which allows certain 'state'
## to be lag-compensated, such as position.
## It also has a MultiplayerSynchronizer to allow some of the server's state
## variables to br synchronized to the client, such as peer_id, etc.

enum PLAYER_COLORS {
	YELLOW,
	GREEN,
	BLUE,
	RED,
}

enum STATES {
	IDLE,
	WALKING,
	DYING,
}

@export var current_state = STATES.IDLE

@export var max_speed = 120.0
@export var acceleration = 300.0
@export var deceleration = 300.0

# We gather the player input from this separate script, which can be independently synchronized to the server
@onready var player_input: PlayerInput = $player_input

# This peer_id gets synchronized by a MultiplayerSynchronizer, only on change
@export var peer_id: int = -1

@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer
@onready var tick_interpolator: TickInterpolator = $TickInterpolator
@onready var animation_player: AnimationPlayer = $visual/AnimationPlayer
@onready var weapon_pivot: Node2D = $weapon_pivot
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $audio/AudioStreamPlayer2D

var audio_footsteps = [
	preload("res://assets/audio/effects/footsteps/footstep_concrete_000.ogg"),
	preload("res://assets/audio/effects/footsteps/footstep_concrete_001.ogg"),
	preload("res://assets/audio/effects/footsteps/footstep_concrete_002.ogg"),
	preload("res://assets/audio/effects/footsteps/footstep_concrete_003.ogg"),
	preload("res://assets/audio/effects/footsteps/footstep_concrete_004.ogg"),
]

var health: int = 100
#var death_tick: int = -1
var did_respawn: bool = false
#var respawn_position: Vector2
var player_color: PLAYER_COLORS

var pcam: PhantomCamera2D


func _ready() -> void:
	# Connect to NetworkTime signals
	NetworkTime.on_tick.connect(_tick)
	
	# Take a frame for the network to synchronize, etc, and let peer_id be set.
	await get_tree().process_frame
	
	# Ensure that the server/host is the authority over the player node
	set_multiplayer_authority(1)
	
	# Grant the particular peer_id authority over this player's input node.
	# Netfox uses Server Authority over the player node, but we grant Client
	# Authority to the player_input node.
	player_input.set_multiplayer_authority(peer_id)
	
	# Activate the Rollback Synchronizer's settings - needed, otherwise the client gets rolled back 
	rollback_synchronizer.process_settings()
	
	# Get hold of the camera so it can track the player
	if player_input.is_multiplayer_authority():
		pcam = get_tree().get_first_node_in_group("PhantomCamera2D")
		pcam.set_follow_target(self)


func _tick(_dt:float, _tk: int):
	# Check health
	if health <= 0:
		Log.pr("Player died")

	apply_animation()



func _rollback_tick(_delta, _tk, _is_fresh) -> void:
	if player_input.just_die:
		Log.pr("Noticed die signal in player's rollback tick")
		die()
	
	
	# Calculate movement from velocity
	velocity = player_input.input_direction * max_speed
	
	# Limit the maximum velocity of the actor
	velocity = velocity.limit_length(max_speed)
	
	# Set player's state based on velocity, etc.
	if velocity.length() > 0:
		current_state = STATES.WALKING
	else:
		current_state = STATES.IDLE
	
	# Apply the velocity
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor
	
	# Aim weapon
	weapon_pivot.look_at(position + player_input.aim_direction)


# Play the appropriate animation based on the player's velocity
func apply_animation() -> void:
	match current_state:
		STATES.IDLE:
			animation_player.speed_scale = 1.0
			animation_player.play("player_animations/player_idle" + "_" + PLAYER_COLORS.keys()[player_color].to_lower())
		STATES.WALKING:
			animation_player.speed_scale = clampf(velocity.length() / max_speed, 0.2, 1.0)
			animation_player.play("player_animations/player_walk" + "_" + PLAYER_COLORS.keys()[player_color].to_lower())
			
	#if velocity == Vector2.ZERO:
		#animation_player.speed_scale = 1.0
		#animation_player.play("player_animations/player_idle" + "_" + PLAYER_COLORS.keys()[player_color].to_lower())
	#else:
		#animation_player.speed_scale = clampf(velocity.length() / max_speed, 0.2, 1.0)
		#animation_player.play("player_animations/player_walk" + "_" + PLAYER_COLORS.keys()[player_color].to_lower())


func footstep_audio() -> void:
	audio_stream_player_2d.stream = audio_footsteps.pick_random()
	audio_stream_player_2d.pitch_scale = randf_range(0.8, 1.2)
	audio_stream_player_2d.play()


func die() -> void:
	# Only the authority can decide if a player died
	if not is_multiplayer_authority():
		return

	# The recent death_tick is conveyed to the clients by the
	# authority as a synchronized variable
	#death_tick = NetworkTime.tick
	#respawn_position = SpawnPoints.get_free_spawn_point_position()
	
	current_state = STATES.DYING
	
	Events.game_events.player_died.emit(peer_id)
	
	# Once cleaned up, call dead
	dead()


func dead() -> void:
	queue_free()
	
