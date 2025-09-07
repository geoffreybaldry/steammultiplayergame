extends Node

var app_id: int = ProjectSettings.get_setting("steam/initialization/app_id")
var steam_enabled: bool = false

var app_installed_depots: Array
var app_languages: String
var app_owner: int
var build_id: int
var game_language: String
var install_dir: Dictionary
var is_on_steam_deck: bool
var is_on_vr: bool
var is_online: bool
var is_owned: bool
var launch_command_line: String
var steam_id: int
var steam_username: String
var ui_language: String

signal steamworks_error

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initialize_steam()

func _process(_delta: float) -> void:
	Steam.run_callbacks()


func initialize_steam() -> void:
	if not Engine.has_singleton("Steam"):
		Log.pr("This version somehow is missing Steamworks. Shutting down Game.")
		steamworks_error.emit("This version somehow is missing Steamworks! Game will now shut down. Check your log files to find out more.")
		return
		
	if not Steam.isSteamRunning():
		Log.pr("Steam is not running. Shutting down Game.")
		steamworks_error.emit("Steam is not running. Game will now shut down. Check your log files to find out more.")
		return
	
	#if not Steam.restartAppIfNecessary(app_id):
		#Log.pr("Game was not launched through the Steam client. Shutting down Game and relaunching through Steam.")
		#steamworks_error.emit("Game was not launched through the Steam client. Game will now shut down and restart from Steam!")
		#return
		
	# Initialize Steam
	var initialize_response: Dictionary = Steam.steamInitEx(app_id, true)
	Log.pr("Did Steam initialize?: %s" % initialize_response)

	if initialize_response['status'] > Steam.STEAM_API_INIT_RESULT_OK:
		# Should trigger a pop-up in boot process to inform user the game is shutting down instead of just closing
		Log.pr("Failed to initialize Steam. Reason: %s" % initialize_response['verbal']) # Was ['verbose']
		steamworks_error.emit("Failed to initialized Steam! Game will now shut down. Check your log files to find out more.")
		return

	steam_enabled = true
	
	app_installed_depots = Steam.getInstalledDepots( app_id )
	app_languages = Steam.getAvailableGameLanguages()
	app_owner = Steam.getAppOwner()
	build_id = Steam.getAppBuildId()
	game_language = Steam.getCurrentGameLanguage()
	install_dir = Steam.getAppInstallDir( app_id )
	is_on_steam_deck = Steam.isSteamRunningOnSteamDeck()
	is_on_vr = Steam.isSteamRunningInVR()
	is_online = Steam.loggedOn()
	is_owned = Steam.isSubscribed()
	launch_command_line = Steam.getLaunchCommandLine()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()
	ui_language = Steam.getSteamUILanguage()

	Log.pr("App Owner : " + str(app_owner))
	Log.pr("Steam Username : " + steam_username)
