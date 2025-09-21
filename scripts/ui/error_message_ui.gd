extends Control

@onready var v_box_container: VBoxContainer = $VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.error_messages.error_message.connect(_on_error_message)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_error_message(message: String) -> void:
	# Create a new Label Control instance
	var label_instance: Label = Label.new()
	label_instance.text = message
	label_instance.add_theme_font_override("Font", preload("res://assets/fonts/m3x6.ttf") )
	v_box_container.add_child(label_instance)
