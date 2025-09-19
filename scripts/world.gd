extends Node2D

## This scene is the root of the game world - It's the "Main Scene".
## Other scenes like Main Menu UI, Multiplayer Lobby, or the Game's Levels
## are all added or removed as children of this World scene.
## The World scene persist through the entire execution of the game.

@onready var ui_canvas_layer: CanvasLayer = $ui_canvas_layer

var main_menu_ui_scene: PackedScene = preload("res://scenes/ui/main_menu_ui.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Log.pr("world ready, adding_main_menu_ui scene")
	
	# This is a small scene, so a breif "hitch" when it instantiates is acceptable
	var main_menu_ui_instance = main_menu_ui_scene.instantiate()
	ui_canvas_layer.add_child(main_menu_ui_instance)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
