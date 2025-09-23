extends Control

@onready var v_box_container: VBoxContainer = $VBoxContainer

var error_message_label_ui_scene = preload("res://scenes/ui/error_message_label_ui.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.error_messages.error_message.connect(_on_error_message)
	
	# Send a test one
	Events.error_messages.error_message.emit("A test message")


func _on_error_message(message: String) -> void:
	# Create a new Label Control instance
	var label_scene_instance = error_message_label_ui_scene.instantiate()
	label_scene_instance.text = message
	
	# Add the error label to the scene
	v_box_container.add_child(label_scene_instance)
