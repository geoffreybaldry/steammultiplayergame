extends Area2D
class_name SpawnPoint

@onready var timer: Timer = $Timer

var id: String = ""
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var occupying_players: Array[String]
var just_selected: bool = false

func _ready() -> void:
	# Let the spawn manager know we're here (on the server)
	_rng.randomize()
	if is_multiplayer_authority():
		id = generate_id()
		SpawnPoints.register(self, id)


func select() -> void:
	just_selected = true
	timer.start()


func is_available() -> bool:
	return occupying_players.is_empty() and not just_selected


func _on_body_entered(body: Node2D) -> void:
	#Log.pr("Spawn point " + self.name + " area entered by body : " + body.name)
	
	if not occupying_players.has(body.name):
		occupying_players.append(body.name)
	

func _on_body_exited(body: Node2D) -> void:
	#Log.pr("Spawn point " + self.name + " area exited by body : " + body.name)
	
	if occupying_players.has(body.name):
		occupying_players.erase(body.name)


func generate_id(length: int = 12, charset: String = "abcdefghijklmnopqrstuvwxyz0123456789") -> String:
	var result = ""

	# Generate a random ID
	for i in range(length):
		var idx = _rng.randi_range(0, charset.length() - 1)
		result += charset[idx]

	return result


func _on_timer_timeout() -> void:
	just_selected = false
