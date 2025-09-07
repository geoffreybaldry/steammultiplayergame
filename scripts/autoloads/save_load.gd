extends Node

################################################################################
# SAVE / LOAD SCRIPT
# Handles all of our saving and loading files
################################################################################
var file_paths: Dictionary = {
	#"ban_list": "user://ban_list.pan",
	"config_file": "user://config.cfg",
	#"stats": "user://stats.pan"
}


func save_config() -> void:
	Log.pr("Saving the current configuration to file")
	var config_file: ConfigFile = ConfigFile.new()
	
	config_file.set_value("General", "debug_mode", Config.debug_mode)
	config_file.set_value("Display", "display_mode", Config.display_mode)
	config_file.set_value("Display", "display_monitor", Config.display_monitor)
	config_file.set_value("Audio", "game_audio", Config.game_audio)
	
	config_file.save(file_paths['config_file'])
	
	Log.pr("Saved configuration successfully")


func load_config() -> void:
	Log.pr("Loading configuration file")
	var config_file = ConfigFile.new()

	var err = config_file.load(file_paths['config_file'])
	if err != OK:
		Log.pr("Error loading config file " + file_paths['config_file'] + ". Error - " + error_string(err))
		return
	else:
		# General settings
		if config_file.has_section_key("General", "debug_on"):
			Config.debug_mode = config_file.get_value("General", "debug_on")
