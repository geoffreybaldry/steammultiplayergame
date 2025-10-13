extends Node

# Enet Specific
const ENET_ADDRESS: String = "localhost"
const ENET_PORT = 4096

# Network agnostic
const MAX_PEERS: int = 4

enum NETWORK_TYPE {
	NONE,
	ENET,
	STEAM
}

var current_network_type = NETWORK_TYPE.NONE

# This will contain player info for every player,
# with the keys being each player's unique IDs.
# e.g 	{ 
# 			"1" : {"name": "A Player's Name"},
#			"694392204": { "name": JazzyGeoff }
#		}
var players = {}

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var my_player_info = {"name": "Not yet set"}

# Used by the server to keep track of how many players have loaded the level
var players_loaded: int = 0

# Our multiplayer peer id, 0 for not set, 1 for server, any other number for client
var peer_id: int = 0:
	set(value):
		peer_id = value
		peer_id_changed.emit(value)
	get:
		return peer_id

signal server_started()							# Emitted when this peer starts as a server
#signal networktime_client_synced(peer_id: int)	# Emitted when a client syncs its NetFox network time with the server
signal host_server_disconnected         		# Emitted if we see the host server disconnect - bad news
signal peer_connected(peer_id: int)				# Emitted if a peer connects
signal peer_disconnected(peer_id: int)			# Emitted if a peer disconnects so we can let the rest of the game know
signal all_peers_loaded							# Emitted when all peers have loaded the chosen level
signal peer_id_changed(peer_id: int)			# Emitted when our peer_id changes

func _ready() -> void:
	# Connect to multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)             # When this multiplayer_peer connects to a new peer
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)       # When this multiplayer_peer is disconnected from a peer
	# Only emitted on Clients...
	multiplayer.connected_to_server.connect(_on_connected_to_server)   # Connected to a server
	multiplayer.connection_failed.connect(_on_connection_failed)       # Failed to connect to a server
	multiplayer.server_disconnected.connect(_on_server_disconnected)   # When this client disconnects from a server

	# Connect to server signal(s)
	server_started.connect(_on_server_started)

	# Connect to NetworkTime signals
	#if multiplayer.is_server():
		#NetworkTime.after_client_sync.connect(_on_networktime_client_sync)

	# Connect to game signals
	GameState.game_state_changed.connect(_on_game_state_changed)


# Convenient signal for initiating things when the server starts
func _on_server_started() -> void:
	NetworkTime.start()
	

# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_peer_connected(this_peer_id: int) -> void:
	Log.pr("A peer connected with id " + str(this_peer_id))
	
	peer_connected.emit(this_peer_id)
	
	# Let the player know about us by contacting them directly with an RPC direct to their id (rpc_id)
	register_player.rpc_id(this_peer_id, my_player_info)


func _on_peer_disconnected(this_peer_id: int) -> void:
	Log.pr("A peer disconnected with id " + str(this_peer_id))
	
	peer_disconnected.emit(this_peer_id)
	players.erase(this_peer_id)
	
	Log.prn(players)


func _on_connected_to_server() -> void:
	Log.pr("_on_connected_to_server")
	
	# Start NetFox Network time ticks
	NetworkTime.start()
	
	# Add ourselves to the players list
	peer_id = multiplayer.get_unique_id()
	players[peer_id] = my_player_info
	
	Log.prn(players)
	
	
func _on_connection_failed() -> void:
	Log.warn("_on_connection_failed")
	remove_multiplayer_peer()
	
	
func _on_server_disconnected() -> void:
	Log.warn("_on_server_disconnected")
	host_server_disconnected.emit()
	Events.error_messages.error_message.emit("Host Server Disconnected from Network")
	remove_multiplayer_peer()


# Not really used - probably should delete
#func _on_networktime_client_sync(this_peer_id: int) -> void:
	#Log.pr("Peer " + str(this_peer_id) + " synchronized its time to the server")
	#networktime_client_synced.emit(this_peer_id)
	

# Watch for changes in the game state, and adjust steam networking to suit
func _on_game_state_changed(_old_game_state: int, new_game_state: int) -> void:
	#Log.pr("_on_game_state_changed : ", old_game_state, new_game_state)
	
	match new_game_state:
		GameState.GAME_STATES.MAIN_MENU:
			current_network_type = NETWORK_TYPE.NONE
			remove_multiplayer_peer() # Currently causes player.gd to error because it's too harsh
		GameState.GAME_STATES.ENET_MENU:
			current_network_type = NETWORK_TYPE.ENET
		GameState.GAME_STATES.STEAM_LOBBY_MENU:
			current_network_type = NETWORK_TYPE.STEAM


func create_network() -> void:
	Log.pr("Creating Network as Host...")
	
	var err: Error
	var multiplayer_peer
	
	if current_network_type == NETWORK_TYPE.ENET:
		multiplayer_peer = ENetMultiplayerPeer.new()
		err = multiplayer_peer.create_server(ENET_PORT, MAX_PEERS)
	elif current_network_type == NETWORK_TYPE.STEAM:
		multiplayer_peer = SteamMultiplayerPeer.new()
		#multiplayer_peer.set_debug_level(SteamMultiplayerPeer.DEBUG_LEVEL_PEER)
		err = multiplayer_peer.create_host()
	else:
		Log.warn("NETWORK_TYPE is not set while creating multiplayer_peer as host/server.")
		
	if err == OK:
		multiplayer.multiplayer_peer = multiplayer_peer
		peer_id = 1 # The game host is always id 1
		
		server_started.emit()

		my_player_info["name"] = "Host User"
		players[peer_id] = my_player_info
	else:
		Log.warn("Error creating Host Network, Error: " + error_string(err))
	
	Log.pr("Waiting for players to Join...")
	Log.prn(players)


func join_network(host_steam_id: int = 0) -> void:
	Log.pr("Joining Network as client")
	
	var err: Error
	var multiplayer_peer
	
	if current_network_type == NETWORK_TYPE.ENET:
		multiplayer_peer = ENetMultiplayerPeer.new()
		err = multiplayer_peer.create_client(ENET_ADDRESS, ENET_PORT)
	elif current_network_type == NETWORK_TYPE.STEAM:
		multiplayer_peer = SteamMultiplayerPeer.new()
		#multiplayer_peer.set_debug_level(SteamMultiplayerPeer.DEBUG_LEVEL_PEER)
		err = multiplayer_peer.create_client(host_steam_id)
	else:
		Log.warn("NETWORK_TYPE is not set while creating multiplayer_peer as client.")
	
	if err == OK:
		multiplayer.multiplayer_peer = multiplayer_peer
		my_player_info["name"] = Steamworks.steam_username
	else:
		Log.warn("Error connecting to host, Error: " + error_string(err))


# Used to reset the multiplayer peer back to starting state
func remove_multiplayer_peer() -> void:
	#Log.warn("Calling remove_multiplayer_peer()")
	if peer_id == 0:
		return
	
	NetworkTime.stop()
	multiplayer.multiplayer_peer = null
	peer_id = 0
	
	# I see people talking about doing this instead of = null above - investigate it, Geoff
	#NetworkTime.stop()
	#multiplayer.multiplayer_peer.close()
	#multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

	players.clear()


##########################
########## RPCs ##########
##########################
@rpc("call_local", "any_peer")
func register_player(this_player_info) -> void:
	Log.pr("Registering player with name " + this_player_info['name'])
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = this_player_info
	
	Log.prn(players)
	

# Every peer will call this when they have loaded the game scene.
# Only the server needs to keep track of the number of players loaded.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	Log.pr("Player loaded scene - Player ID : " + str(multiplayer.get_remote_sender_id()))
	if multiplayer.is_server():
		players_loaded += 1
		Log.pr("Players in game : " + str(players_loaded) + "/" + str(players.size()))
		if players_loaded == players.size():
			Log.pr("All required players in game : " + str(players_loaded) + "/" + str(players.size()))
			all_peers_loaded.emit()
			players_loaded = 0
