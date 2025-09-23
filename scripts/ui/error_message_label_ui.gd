extends Label

@onready var timer: Timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Update the label's characteristics
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_override("font", preload("res://assets/fonts/m3x6.ttf") )
	add_theme_font_size_override("font_size", 16)


# Remove the Label once it has displayed for the timer's duration
func _on_timer_timeout() -> void:
	queue_free()
