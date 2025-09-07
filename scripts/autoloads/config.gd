extends Node

# General
var debug_mode: bool = true

# Display
@export var display_mode: int = Window.MODE_MAXIMIZED: set = update_display_mode
@export var display_monitor: int = 0 : set = update_display_monitor

# Audio
var game_audio: Dictionary = {
	"last_track":"Menu",
	"master": -20,
	"music": -20,
	"sounds": -20,
	"voice": -20
}


func update_display_mode(new_display_mode: int) -> void:
	if Steamworks.is_on_steam_deck:
		Log.pr("User is on Steam Deck, ignoring display changes")
		get_tree().get_root().call_deferred("set_mode", Window.MODE_EXCLUSIVE_FULLSCREEN)
	else:
		display_mode = new_display_mode
		Log.pr("Setting display to: %s" % display_mode)
		get_tree().get_root().call_deferred("set_mode", display_mode)
	
	
func update_display_monitor(new_display_monitor: int) -> void:
	DisplayServer.window_set_current_screen(new_display_monitor)
