extends Node

const MAX_PEERS: int = 4

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players = {}

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var my_player_info = {"name": "Not yet set"}

var players_loaded: int = 0

signal host_server_disconnected
signal peer_disconnected(peer_id: int)	# Emitted if a peer disconnectes so we can let the rest of the game know
signal all_peers_loaded					# Emitted when all peers have loaded the chosen level


func _ready() -> void:
	# Connect to multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)             # When this multiplayer_peer connects to a new peer
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)       # When this multiplayer_peer is disconnected from a peer
	# Only emitted on Clients...
	multiplayer.connected_to_server.connect(_on_connected_to_server)   # Connected to a server
	multiplayer.connection_failed.connect(_on_connection_failed)       # Failed to connect to a server
	multiplayer.server_disconnected.connect(_on_server_disconnected)   # When this client disconnects from a server


###################################
##### MultiplayerPeer signals #####
###################################
# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_peer_connected(this_peer_id: int) -> void:
	Log.pr("A peer connected with id " + str(this_peer_id))
	
	# Let the player know about us by contacting them directly with an RPC direct to their id (rpc_id)
	register_player.rpc_id(this_peer_id, my_player_info)


func _on_peer_disconnected(this_peer_id: int) -> void:
	Log.pr("A peer disconnected with id " + str(this_peer_id))
	
	peer_disconnected.emit(this_peer_id)
	players.erase(this_peer_id)
	
	Log.prn(players)


func _on_connected_to_server() -> void:
	Log.pr("_on_connected_to_server")
	# Add ourselves to the players list
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = my_player_info
	
	Log.prn(players)
	
	
func _on_connection_failed() -> void:
	Log.pr("_on_connection_failed")
	remove_multiplayer_peer()
	
	
func _on_server_disconnected() -> void:
	Log.pr("_on_server_disconnected")
	host_server_disconnected.emit()
	remove_multiplayer_peer()


##########################
##### Game Functions #####
##########################
func create_network() -> void:
	Log.pr("Creating Network as Host...")
	var multiplayer_peer = SteamMultiplayerPeer.new()
	#multiplayer_peer.set_debug_level(SteamMultiplayerPeer.DEBUG_LEVEL_PEER)
	var err = multiplayer_peer.create_host()
	if err == OK:
		multiplayer.multiplayer_peer = multiplayer_peer
		my_player_info["name"] = Steamworks.steam_username
		players[1] = my_player_info # The game host is always id 1
	else:
		Log.pr("Error creating Host Network, Error: " + error_string(err))
	
	Log.pr("Waiting for players to Join...")
	
	Log.prn(players)


func join_network(host_steam_id: int) -> void:
	Log.pr("Joining Network as client of Host " + str(host_steam_id))
	var multiplayer_peer = SteamMultiplayerPeer.new()
	#multiplayer_peer.set_debug_level(SteamMultiplayerPeer.DEBUG_LEVEL_PEER)
	var err = multiplayer_peer.create_client(host_steam_id)
	if err == OK:
		multiplayer.multiplayer_peer = multiplayer_peer
		my_player_info["name"] = Steamworks.steam_username
	else:
		Log.pr("Error connecting to steam host " + str(host_steam_id) + ", Error: " + error_string(err))


# Used to reset the multiplayer peer back to starting state
func remove_multiplayer_peer() -> void:
	multiplayer.multiplayer_peer = null
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
