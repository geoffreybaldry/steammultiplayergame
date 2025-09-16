extends Node

@export var input_direction: Vector2 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Read input from local player
	input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
