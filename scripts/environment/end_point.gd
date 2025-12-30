extends Area2D

#@export var endpoint_target_level: String

@onready var texture_progress_bar: TextureProgressBar = $visual/TextureProgressBar
@onready var timer: Timer = $Timer

var occupying_players: Array[String]
var countdown_running: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if occupying_players.is_empty():
		texture_progress_bar.value = 0
		timer.stop()
		countdown_running = false
		return
		
	if countdown_running:
		if occupying_players.size() != Network.players.size():
			timer.stop()
			countdown_running = false
		else:
			# Adjust the visual progress
			var time_progress: float = 100 - (timer.time_left / timer.wait_time) * 100
			texture_progress_bar.value = time_progress


func _on_body_entered(body: Node2D) -> void:
	if not occupying_players.has(body.name):
		occupying_players.append(body.name)
		
		if occupying_players.size() == Network.players.size():
			timer.start()
			countdown_running = true


func _on_body_exited(body: Node2D) -> void:
	if occupying_players.has(body.name):
		occupying_players.erase(body.name)


func _on_timer_timeout() -> void:
	timer.stop()
	
	# Only the Server decides if the level is complete
	if is_multiplayer_authority():
		Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Level Complete!")
		# Let all the Peers know that the level is complete
		Levels._on_level_complete.rpc()
