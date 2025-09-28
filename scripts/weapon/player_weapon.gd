extends NetworkWeapon2D
class_name PlayerWeapon

@export var projectile: PackedScene
@export var fire_cooldown: float = 0.15

@onready var player_input: PlayerInput = $"../player_input"
#@onready var sound: AudioStreamPlayer3D = $AudioStreamPlayer3D

var last_fire: int = -1

static var _logger := _NetfoxLogger.new("fb", "BrawlerWeapon")

func _ready():
	NetworkTime.on_tick.connect(_tick)

func _can_fire() -> bool:
	return NetworkTime.seconds_between(last_fire, NetworkTime.tick) >= fire_cooldown

func _can_peer_use(peer_id: int) -> bool:
	return peer_id == player_input.get_multiplayer_authority()

func _after_fire(projectile: Node2D):
	var projectile_bullet := projectile as ProjectileBullet
	last_fire = get_fired_tick()
	#sound.play()

	_logger.trace("[%s] Ticking new bomb %d -> %d", [projectile_bullet.name, get_fired_tick(), NetworkTime.tick])
	for t in range(get_fired_tick(), NetworkTime.tick):
		if projectile_bullet.is_queued_for_deletion():
			break
		projectile_bullet._tick(NetworkTime.ticktime, t)

func _spawn() -> Node2D:
	var projectile_bullet: ProjectileBullet = projectile.instantiate() as ProjectileBullet
	get_tree().root.add_child(projectile_bullet, true)
	projectile_bullet.global_transform = global_transform
	projectile_bullet.fired_by = get_parent()

	return projectile_bullet

func _tick(_delta: float, _t: int):
	#if player_input.is_firing:
	if player_input.just_fired:
		fire()
