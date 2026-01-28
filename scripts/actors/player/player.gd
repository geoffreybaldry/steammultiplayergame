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
## variables to br synchronized to the client.

enum PLAYER_COLORS {
	YELLOW,
	GREEN,
	BLUE,
	RED,
}

@export var max_health: float = 5
@export var max_speed = 300.0
@export var acceleration = 30.0
@export var deceleration = 30.0

# We gather the player input from this separate script, which can be independently synchronized to the server
@onready var player_input: PlayerInput = $player_input

# This peer_id gets synchronized by a MultiplayerSynchronizer, only on change
@export var peer_id: int = -1

@onready var state_machine: RewindableStateMachine = $RewindableStateMachine
@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer
@onready var tick_interpolator: TickInterpolator = $TickInterpolator
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var animation_player: AnimationPlayer = $visual/AnimationPlayer
@onready var weapon_pivot: Node2D = $weapon_pivot
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hitbox_collision_shape_2d: CollisionShape2D = $HitBox/CollisionShape2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $audio/AudioStreamPlayer2D
@onready var healthbar: TextureProgressBar = $visual/healthbar
@onready var state_label: Label = $visual/state_label

var is_player_enabled: bool = false :
	set(value):
		is_player_enabled = value
		player_enabled(value)

var health: float = max_health
var player_color: PLAYER_COLORS
var pcam: PhantomCamera2D
var spawn_tick: int
var spawn_position: Vector2
var did_spawn: bool
var is_dying: bool = false
var shove_vector: Vector2


func _ready() -> void:
	# Connect to NetworkTime signals
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
	
	# If we are the player that holds the input, then also grab focus from the player phantom camera
	if player_input.is_multiplayer_authority():
		grab_pcam()
	
	# Set starting state
	state_machine.state = &"IDLE"
	
	# Register ourselves as a player game entity
	Events.game_events.register_player_instance.emit(peer_id, self)


func check_spawn(tick) -> void:
	if tick == spawn_tick:
		global_position = spawn_position
		did_spawn = true
		is_player_enabled = true
		if player_input.is_multiplayer_authority():
			grab_pcam()
	else:
		did_spawn = false


# Processes that are re-simulated during rollback
func _rollback_tick(_delta: float, tick: int, _is_fresh: bool) -> void:
	check_spawn(tick) 		# Check if the player needs to spawn
	
	if not is_player_enabled:
		return
	
	if player_input.just_die:
		is_dying = true

	# Handle the "shoving" centrally here, as it applies to all states
	if shove_vector:
		# Shove navigation logic
		velocity = shove_vector
		update_velocity(velocity)
		# Diminish the shove vector over time
		shove_vector = shove_vector.move_toward(Vector2.ZERO, deceleration)
		if shove_vector.length() < 5:
			shove_vector = Vector2.ZERO
			
	# Aim weapon
	weapon_pivot.look_at(position + player_input.aim_direction)

	# Check health condition
	if health <= 0:
		health = max_health
		is_dying = true

# Processes that happen at the end of a tick loop
func _after_tick_loop():
	healthbar.value = (health / max_health) * 100
	
	if did_spawn:
		Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Spawned peer id " + str(peer_id))
		tick_interpolator.teleport()


func update_velocity(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	velocity = velocity.limit_length(max_speed)
	velocity *= NetworkTime.physics_factor
	move_and_slide()	# move_and_slide assumes physics delta
	velocity /= NetworkTime.physics_factor


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


func damage(value: int) -> void:
	health -= value


# Used to perform "push back" on the player
func shove(direction: Vector2, force: float) -> void:
	Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Got shoved")
	shove_vector = direction * force


func _exit_tree() -> void:
	NetworkTime.after_tick_loop.disconnect(_after_tick_loop)
