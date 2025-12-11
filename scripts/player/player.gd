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
## It also has a MultiplayerSynchronizer to allow some of the server's state
## variables to br synchronized to the client, such as peer_id, etc.

@export var speed = 120.0
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
var death_tick: int = -1
var did_respawn := false
var respawn_tick: int = -1
var respawn_position: Vector2 = Vector2.ZERO
var waiting_to_spawn = false

var pcam: PhantomCamera2D

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
	
	# Activate the Rollback Synchronizer's settings - needed, otherwise the client gets rolled back 
	rollback_synchronizer.process_settings()
	
	NetworkTime.on_tick.connect(_tick)
	NetworkTime.after_tick_loop.connect(_after_tick_loop)

	respawn_position = SpawnPoints.get_free_spawn_point_position()
	Log.pr("Peer ID : " + str(peer_id) + " has spawn location : " + str(respawn_position))

	# Get hold of the camera so it can track the player
	if player_input.is_multiplayer_authority():
		pcam = get_tree().current_scene.get_node("PhantomCamera2D")
		pcam.set_follow_target(self)


func _tick(_dt:float, _tk: int):
	# Check health
	if health <= 0:
		Log.pr("Player died")
		
	if player_input.just_die:
		Log.pr(str(multiplayer.get_unique_id()) + " Dying")
		die()

	apply_animation()
	#apply_audio()

func _after_tick_loop():
	if did_respawn:
		Log.pr("Did Respawn!")
		tick_interpolator.teleport()
		

func _rollback_tick(_delta, tick, _is_fresh) -> void:
	# Check for (re)spawn
	if tick == death_tick:
		spawn_player()
		did_respawn = true
	else:
		did_respawn = false
	
	# Calculate movement from velocity
	velocity = player_input.input_direction * speed
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor
	
	# Aim weapon
	weapon_pivot.look_at(position + player_input.aim_direction)
	

func spawn_player() -> void:
	global_position = respawn_position


func _process(_delta: float) -> void:
	pass
	# Temporary - used to show the player_id, and the id of the authority of the player node
	# Helps with debugging who is in charge of which player nodes.
	#peer_id_label.text = "id : " + str(peer_id)
	#peer_authority_id_label.text = "auth_id : " + str(get_multiplayer_authority())
	#input_authority_id_label.text = "input_auth_id : " + str(player_input.get_multiplayer_authority())


# Play the appropriate animation based on the player's velocity
func apply_animation() -> void:
	if velocity == Vector2.ZERO:
		animation_player.play("idle")
	else:
		animation_player.speed_scale = clampf(player_input.input_direction.length(), 0.2, 1.0)
		animation_player.play("walk")


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
	death_tick = NetworkTime.tick


func enable_player() -> void:
	collision_shape_2d.disabled = false
	#visible = true
	
func disable_player() -> void:
	collision_shape_2d.disabled = true
	#visible = false
