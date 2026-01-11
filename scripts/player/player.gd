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
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var animation_player: AnimationPlayer = $visual/AnimationPlayer
@onready var weapon_pivot: Node2D = $weapon_pivot
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hitbox_collision_shape_2d: CollisionShape2D = $HitBox/CollisionShape2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $audio/AudioStreamPlayer2D


var audio_footsteps = [
	preload("res://assets/audio/effects/footsteps/footstep_concrete_000.ogg"),
	preload("res://assets/audio/effects/footsteps/footstep_concrete_001.ogg"),
	preload("res://assets/audio/effects/footsteps/footstep_concrete_002.ogg"),
	preload("res://assets/audio/effects/footsteps/footstep_concrete_003.ogg"),
	preload("res://assets/audio/effects/footsteps/footstep_concrete_004.ogg"),
]

var is_player_enabled: bool = false :
	set(value):
		is_player_enabled = value
		player_enabled(value)

var health: int = 100
var player_color: PLAYER_COLORS

var pcam: PhantomCamera2D

var spawn_tick: int
var spawn_position: Vector2
var did_spawn: bool
var disable_tick: int
var did_disable: bool

func _ready() -> void:
	# Connect to NetworkTime signals
	#NetworkTime.on_tick.connect(_tick)
	NetworkTime.after_tick_loop.connect(_after_tick_loop)
	
	# New players start disabled
	player_enabled(false)
	
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
	
	## If we are the player that holds the input, then also grab focus from the player phantom camera
	if player_input.is_multiplayer_authority():
		grab_pcam()
		
	# Register ourselves as a game entity
	#if is_multiplayer_authority():
	Events.game_events.register_player_instance.emit(peer_id, self)


# Things that don't need to be involved in rollback go in _process
func _process(_delta: float) -> void:
	if not is_player_enabled:
		return
		
	apply_animation()


func _tick(_dt:float, _tk: int):
	pass


func _after_tick_loop():
	if did_spawn:
		Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Spawned peer id " + str(peer_id))
		tick_interpolator.teleport()
	elif did_disable:
		Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Disabled peer id " + str(peer_id))
		tick_interpolator.teleport()


# Processes that must be re-simulated during rollback
func _rollback_tick(_delta, tick, _is_fresh) -> void:
	if tick == spawn_tick:
		Events.error_messages.error_message.emit("Noticed spawn tick " + str(tick), 5)
		global_position = spawn_position
		did_spawn = true
		is_player_enabled = true
		if player_input.is_multiplayer_authority():
			grab_pcam()
	else:
		did_spawn = false
	#
	#if tick == disable_tick:
		#global_position = spawn_position
		#did_disable = true
		#is_player_enabled = false
	#else:
		#did_disable = false
	
	if not is_player_enabled:
		return
	
	if player_input.just_die:
		Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Noticed die signal in player's rollback tick")
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


# Function that "turns on or off" the player
func player_enabled(value: bool) -> void:
	#Log.warn("[" + str(multiplayer.get_unique_id()) + "]" + " " + "player_enabled() : " + str(peer_id) + " " + str(value))
	if value:
		collision_shape_2d.set_deferred("disabled", false)
		hitbox_collision_shape_2d.set_deferred("disabled", false)
		visible = true
	else:
		collision_shape_2d.set_deferred("disabled", true)
		hitbox_collision_shape_2d.set_deferred("disabled", true)
		visible = false
	


# Play the appropriate animation based on the player's velocity
func apply_animation() -> void:
	match current_state:
		STATES.IDLE:
			animation_player.speed_scale = 1.0
			animation_player.play("player_animations/player_idle" + "_" + PLAYER_COLORS.keys()[player_color].to_lower())
		STATES.WALKING:
			animation_player.speed_scale = clampf(velocity.length() / max_speed, 0.2, 1.0)
			animation_player.play("player_animations/player_walk" + "_" + PLAYER_COLORS.keys()[player_color].to_lower())


func footstep_audio() -> void:
	audio_stream_player_2d.stream = audio_footsteps.pick_random()
	audio_stream_player_2d.pitch_scale = randf_range(0.8, 1.2)
	audio_stream_player_2d.play()


func die() -> void:
	# Only the authority (Server) can decide if a player died
	if is_multiplayer_authority():
		#current_state = STATES.DYING
		Events.game_events.player_died.emit(peer_id)


func grab_pcam() -> void:
	pcam = get_tree().get_first_node_in_group("player_phantom_camera")
	pcam.set_follow_target(self)





#@rpc("any_peer", "call_local", "reliable")
#func disable_entity() -> void:
	#Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Disabling RBS on player id " + str(peer_id))
	## Disabling RBS and allowing in-flight RPCs to drain stops debug errors on the server
	#rollback_synchronizer.state_properties = []
	#rollback_synchronizer.input_properties = []
	#rollback_synchronizer.process_settings()
	#
	#visible = false
	#collision_shape_2d.disabled = true
	#hitbox_collision_shape_2d.disabled = true


#func dead() -> void:
	#if not is_multiplayer_authority():
		#return
		#
	#queue_free()
	

func _exit_tree() -> void:
	NetworkTime.on_tick.disconnect(_tick)
