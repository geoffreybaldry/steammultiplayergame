extends Node2D

const PACKET_READ_LIMIT: int = 32
const M_3X_6: Font = preload("res://assets/fonts/m3x6.ttf")
const LOBBY_MEMBERS_MAX: int = 4

signal lobby_members_updated

var lobby_id: int = 0:
	set(value):
		if value > 0:
			update_lobby_button_state("IN-LOBBY")
		else:
			update_lobby_button_state("NOT-IN-LOBBY")
		lobby_id = value
	get:
		return lobby_id

var lobby_owner_id: int = 0:
	set(value):
		if value == 0:
			update_game_button_state("CLEAR")
		elif value == Steamworks.steam_id:
			update_game_button_state("START")
		lobby_owner_id = value
	get:
		return lobby_owner_id
		
var lobby_members: Array = []



# UI
@onready var steam_name_label: Label = $user_info_vbox/steam_name_label
@onready var steam_id_label: Label = $user_info_vbox/steam_id_label
@onready var lobby_code_text_area: TextEdit = $top_buttons_hbox/lobby_code_text_area
@onready var players_count: Label = $players_and_chat_hbox/players_panel/players_count
@onready var players_list: RichTextLabel = $players_and_chat_hbox/players_panel/players_list
@onready var chat_messages: RichTextLabel = $players_and_chat_hbox/messaging_vbox/chat_panel/chat_messages
@onready var message_line_edit: LineEdit = $players_and_chat_hbox/messaging_vbox/HBoxContainer/message_line_edit

# Buttons
@onready var create_lobby_button: Button = $top_buttons_hbox/create_lobby_button
@onready var join_lobby_button: Button = $top_buttons_hbox/join_lobby_button
@onready var send_message_button: Button = $players_and_chat_hbox/messaging_vbox/HBoxContainer/send_message_button
@onready var leave_lobby_button: Button = $bottom_buttons_control/leave_lobby_button
@onready var start_game_button: Button = $bottom_buttons_control/start_game_button
@onready var ready_game_button: Button = $bottom_buttons_control/ready_game_button
@onready var join_game_button: Button = $bottom_buttons_control/join_game_button


func _ready() -> void:
	steam_name_label.text = Steamworks.steam_username
	steam_id_label.text = str(Steamworks.steam_id)
	
	# Steam signals
	Steam.lobby_created.connect(_on_lobby_created)           # When a lobby gets created by you.
	Steam.lobby_match_list.connect(_on_lobby_match_list)     # When lobbies are discovered by you.
	Steam.lobby_joined.connect(_on_lobby_joined)             # When a lobby is joined by you (you join if you created the lobby, too).
	Steam.join_requested.connect(_on_lobby_join_requested)   # When a user requests to join a lobby through Steam overlay or invite.
	Steam.persona_state_change.connect(_on_persona_change)   # When a joined user's data changes, like steam name, or online/offline, etc.
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)   # When the lobby changes in some way, like a user joining or leaving.
	Steam.lobby_data_update.connect(_on_lobby_data_update)   # When the lobby metadata changes, i.e via Steam.setLobbyData().
	#Steam.lobby_invite.connect(_on_lobby_invite)
	Steam.lobby_message.connect(_on_lobby_message)
	
	# SteamNetwork signals
	SteamNetwork.host_server_disconnected.connect(_on_host_server_disconnected)
	
	# Local signals
	lobby_members_updated.connect(_on_lobby_members_updated) # Update the player list, and in turn the UI.
	
	# Check for command line arguments
	check_command_line()
	
	
#########################
##### Steam signals #####
#########################
func _on_lobby_created(conn: int, this_lobby_id: int) -> void:
	if conn == 1:
		# Set the lobby ID
		lobby_id = this_lobby_id
		Log.pr("Created a lobby: %s" % lobby_id)

		# Set this lobby as joinable, just in case, though this should be done by default
		Steam.setLobbyJoinable(lobby_id, true)

		# Set some lobby data
		var lobby_code = str(randi_range(10000, 99999))
		Steam.setLobbyData(lobby_id, "code", lobby_code)

		# Allow P2P connections to fallback to being relayed through Steam if needed
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		Log.pr("Allowing Steam to be relay backup: %s" % set_relay)
		
		# Put the lobby code into the UI panel, so it can be socialized to other players
		lobby_code_text_area.text = lobby_code
		
		# Start multiplayer_peer networking
		SteamNetwork.create_network()


func _on_lobby_match_list(these_lobbies: Array) -> void:
	Log.pr("Received lobbies: " + str(these_lobbies.size()))
	
	if these_lobbies.size() >= 1:
		display_message("Found lobby, joining...")
		Steam.joinLobby(these_lobbies[0])
	else:
		display_message("Failed to find lobby")
		

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# If joining was successful
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		Log.pr("Success - joined Lobby id " + str(this_lobby_id))
		display_message(Steamworks.steam_username + "> You joined the lobby. Share the code to your friends.")
		
		# Set this lobby ID as your lobby ID
		lobby_id = this_lobby_id

		# Get the lobby members
		get_lobby_members()
		
		# Join the multiplayer_peer network, unless we are already the host
		if Steam.getLobbyOwner(lobby_id) != Steamworks.steam_id:
			SteamNetwork.join_network(lobby_owner_id)

	# Else it failed for some reason
	else:
		# Get the failure reason
		var fail_reason: String

		match response:
			Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: fail_reason = "This lobby no longer exists."
			Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: fail_reason = "You don't have permission to join this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: fail_reason = "The lobby is now full."
			Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: fail_reason = "Uh... something unexpected happened!"
			Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: fail_reason = "You are banned from this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: fail_reason = "You cannot join due to having a limited account."
			Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: fail_reason = "This lobby is locked or disabled."
			Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: fail_reason = "This lobby is community locked."
			Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: fail_reason = "A user in the lobby has blocked you from joining."
			Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: fail_reason = "A user you have blocked is in the lobby."

		var error_message = "Failed to join this chat room: %s" % fail_reason
		Log.error(error_message)
		display_message(error_message)


func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
	# Get the lobby owner's name
	var owner_name: String = Steam.getFriendPersonaName(friend_id)
	
	Log.pr("Joining %s's lobby..." % owner_name)
	
	# Attempt to join the lobby
	join_lobby(this_lobby_id)


# A user's information has changed
func _on_persona_change(this_steam_id: int, _flag: int) -> void:
	Log.pr("_on_persona_change, steam_id: " + str(this_steam_id) + ", flag: " + str(_flag))
	# Make sure you're in a lobby and this user is valid or Steam might spam your console log
	if lobby_id > 0:
		Log.pr("A user (%s) had information change, update the lobby list" % this_steam_id)
	
		# Update the player list
		get_lobby_members()


func _on_lobby_chat_update(_this_lobby_id: int, changed_id: int, _making_change_id: int, chat_state: int) -> void:
	# Get the user who has made the lobby change
	var changer_name: String = Steam.getFriendPersonaName(changed_id)
	
	# If a player has joined the lobby
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		Log.pr("%s has joined the lobby." % changer_name)
		display_message("%s has joined the lobby." % changer_name)
	
	# Else if a player has left the lobby
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		Log.pr("%s has left the lobby." % changer_name)
		display_message("%s has left the lobby." % changer_name)
	
	# Else if a player has disconnected without specifically leaving the lobby (network issue, etc)
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED:
		Log.pr("%s has disconnected from the lobby." % changer_name)
		
	# Else if a player has been kicked
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		Log.pr("%s has been kicked from the lobby." % changer_name)
	
	# Else if a player has been banned
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		Log.pr("%s has been banned from the lobby." % changer_name)
	
	# Else there was some unknown change
	else:
		Log.pr("%s did... something." % changer_name)
		display_message("%s did... something." % changer_name)
	
	# Update the lobby now that a change has occurred
	get_lobby_members()


func _on_lobby_data_update(success, this_lobby_id, this_member_id):
	Log.pr("_on_lobby_data_update - Success: " + str(success), "Lobby ID: " + str(this_lobby_id), "Member ID: " + str(this_member_id))

func _on_lobby_message(this_lobby_id: int, this_user: int, this_message: String, _chat_type: int) -> void:
	# If this message was intended for our lobby id
	if this_lobby_id == lobby_id:
		display_message(get_user_name_by_id(this_user) + "> " + this_message)


################################
##### SteamNetwork Signals #####
################################
func _on_host_server_disconnected() -> void:
	Log.pr("_on_host_server_disconnected")
	leave_lobby()
	display_message("The Host Server disconnected")
	

########################
##### Game Signals #####
########################
func _on_lobby_members_updated() -> void:
	players_count.text = "Players (" + str(lobby_members.size()) + ")"
	
	players_list.clear()
	for member in lobby_members:
		players_list.add_text(member['steam_name'] + "\n")


##########################
##### Game Functions #####
##########################
func create_lobby() -> void:
	# Make sure a lobby is not already set
	if lobby_id == 0:
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, LOBBY_MEMBERS_MAX)
		display_message("Creating Lobby...")
	else:
		Log.pr("Error : Lobby already created with id " + str(lobby_id))


func search_lobby(this_lobby_code: String) -> void:
	Log.pr("Searching for Lobby with code %s" % this_lobby_code)
	
	# Set distance to worldwide
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	# Look for specific metadata in Lobby
	Steam.addRequestLobbyListStringFilter("code", this_lobby_code, Steam.LOBBY_COMPARISON_EQUAL)
	Log.pr("Requesting Lobby List")
	Steam.requestLobbyList()


func join_lobby(this_lobby_id: int) -> void:
	Log.pr("Attempting to join lobby with id %s" % this_lobby_id)

	# Clear any previous lobby members lists, if you were in a previous lobby
	lobby_members.clear()

	## Make the lobby join request to Steam
	Steam.joinLobby(this_lobby_id)


func get_lobby_members() -> void:
	Log.pr("get_lobby_members()")
	# Clear your previous lobby list
	lobby_members.clear()
	
	# Get the current/new owner of the Lobby, and detect if ownership has changed hands
	var new_lobby_owner_id = Steam.getLobbyOwner(lobby_id)
	if lobby_owner_id != 0 && new_lobby_owner_id != lobby_owner_id && new_lobby_owner_id == Steamworks.steam_id:
		display_message(Steamworks.steam_username +  "> You became the lobby owner.")
	lobby_owner_id = new_lobby_owner_id
	
	# Get the number of members in this lobby from Steam
	var num_of_members: int = Steam.getNumLobbyMembers(lobby_id)
	
	# Get the data of these players from Steam
	for this_member in range(0, num_of_members):
		# Get the member's Steam ID
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)
	
		# Get the member's Steam name
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
	
		# Add them to the list
		lobby_members.append({"steam_id":member_steam_id, "steam_name":member_steam_name})
		
	emit_signal("lobby_members_updated")


func leave_lobby() -> void:
	# If in a lobby, leave it
	if lobby_id != 0:
		# Send leave request to Steam
		Log.pr("Leaving lobby")
		Steam.leaveLobby(lobby_id)
	
		# Wipe the Steam lobby ID and the lobby owner ID
		lobby_id = 0
		lobby_owner_id = 0
		
		# Disconnect from Steam Network
		SteamNetwork.remove_multiplayer_peer()

		# Clear the local lobby list
		lobby_members.clear()
		emit_signal("lobby_members_updated")


func send_chat_message(this_message: String) -> void:
	# Pass the message to Steam
	var was_sent: bool = Steam.sendLobbyChatMsg(lobby_id, this_message)
	
	# Was it sent successfully?
	if not was_sent:
		var error_message = "ERROR: Chat message failed to send."
		Log.pr(error_message)
		display_message(error_message)


func display_message(message: String) -> void:
	chat_messages.add_text(str(message).strip_edges() + "\n")
	

func start_game() -> void:
	pass
	
	
func join_game() -> void:
	SteamNetwork.join_game(lobby_id)


###################
##### Helpers #####
###################
func check_command_line() -> void:
	var these_arguments: Array = OS.get_cmdline_args()

	# There are arguments to process
	if these_arguments.size() > 0:

		# A Steam connection argument exists
		if these_arguments[0] == "+connect_lobby":

			# Lobby invite exists so try to connect to it
			if int(these_arguments[1]) > 0:
	
				# At this point, you'll probably want to change scenes
				# Something like a loading into lobby screen
				Log.pr("Command line lobby ID: %s" % these_arguments[1])
				join_lobby(int(these_arguments[1]))


func get_user_name_by_id(this_user_id: int) -> String:
	var this_steam_name: String = "Unknown_User"
	for member in lobby_members:
		if member['steam_id'] == this_user_id:
			this_steam_name = member['steam_name']
			break
	return this_steam_name
	

func update_lobby_button_state(state: String) -> void:
	create_lobby_button.disabled = true
	join_lobby_button.disabled = true
	leave_lobby_button.disabled = true
	send_message_button.disabled = true
	message_line_edit.editable = false
	lobby_code_text_area.editable = false
	message_line_edit.clear()
	
	match state:
		"IN-LOBBY":
			leave_lobby_button.disabled = false
			send_message_button.disabled = false
			message_line_edit.editable = true
		"NOT-IN-LOBBY":
			create_lobby_button.disabled = false
			lobby_code_text_area.clear()
			lobby_code_text_area.editable = true
			join_lobby_button.disabled = false
			chat_messages.clear()

func update_game_button_state(state: String) -> void:
	start_game_button.visible = false
	start_game_button.disabled = true
	join_game_button.visible = false
	join_game_button.disabled = true
	ready_game_button.visible = false
	ready_game_button.disabled = true
	
	match state:
		"START":
			start_game_button.visible = true
			start_game_button.disabled = false
		"JOIN":
			join_game_button.visible = true
			join_game_button.disabled = false
		"READY":
			ready_game_button.visible = true
			ready_game_button.disabled = false
		"CLEAR":
			pass
	

##########################
##### Button Signals #####
##########################
func _on_create_lobby_button_pressed() -> void:
	create_lobby()
	

func _on_join_lobby_button_pressed() -> void:
	if not lobby_code_text_area.text:
		return
	search_lobby(lobby_code_text_area.text)
	
	display_message("Finding Lobby " + str(lobby_code_text_area.text) + "...")

func _on_leave_lobby_button_pressed() -> void:
	leave_lobby()


func _on_send_message_button_pressed() -> void:
	# Check if it's worth sending the message
	var this_message = message_line_edit.text
	if this_message.length() > 0:
		send_chat_message(this_message)
		
	message_line_edit.clear()


func _on_start_game_button_pressed() -> void:
	start_game()


func _on_ready_game_button_pressed() -> void:
	pass


func _on_join_game_button_pressed() -> void:
	join_game()
