extends Node2D

@onready var dialogue_label: Label = $dialogue_label
@onready var nine_patch_rect: NinePatchRect = $NinePatchRect

# The player (peer_id) that owns the speech bubble
var player_id: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
