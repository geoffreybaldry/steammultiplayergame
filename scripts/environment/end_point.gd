extends Area2D

@export var endpoint_target_level: String

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
	Log.pr("Level Complete!")
	
	Events.game_events.level_complete.emit()
	
	if endpoint_target_level.is_empty():
		Levels.goto_next_scene()
	else:
		Levels.goto_scene_name(endpoint_target_level)
