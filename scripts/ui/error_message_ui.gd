extends Control

@onready var v_box_container: VBoxContainer = $VBoxContainer

var error_message_label_ui_scene = preload("res://scenes/ui/error_message_label_ui.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.error_messages.error_message.connect(_on_error_message)
	
	# Send a test one
	Events.error_messages.error_message.emit("A 3 second test message", 3.0)


func _on_error_message(message: String, duration: float) -> void:
	# Create a new Label Control instance
	Log.pr("Message " + message + " Duration: " + str(duration))
	var label_scene_instance = error_message_label_ui_scene.instantiate()
	label_scene_instance.text = message
	
	label_scene_instance.call_deferred("start_timer", duration)
	
	# Add the error label to the scene
	v_box_container.add_child(label_scene_instance)
