extends Control

@onready var host_button: Button = $VBoxContainer/host_button
@onready var join_button: Button = $VBoxContainer/join_button
@onready var start_game_button: Button = $start_game_button
@onready var leave_network_button: Button = $leave_network_button
@onready var main_menu_button: Button = $main_menu_button
@onready var status_message_label: Label = $Panel/status_message_label


func _ready() -> void:
	Network.peer_id_changed.connect(_on_peer_id_changed)


func update_enet_button_state(state: String) -> void:
	host_button.disabled = true
	join_button.disabled = true
	leave_network_button.visible = false
	main_menu_button.visible = false
	
	match state:
		"JOINED-NETWORK":
			leave_network_button.visible = true
		"LEFT-NETWORK":
			host_button.disabled = false
			join_button.disabled = false
			host_button.visible = true
			join_button.visible = true
			main_menu_button.visible = true


func update_game_button_state(state: String) -> void:
	start_game_button.visible = false
	start_game_button.disabled = true
	
	match state:
		"START":
			start_game_button.visible = true
			start_game_button.disabled = false
		"CLEAR":
			pass


func _on_peer_id_changed(peer_id: int) -> void:
	Log.pr("_on_peer_id_changed : " + str(peer_id))
	match peer_id:
		0:
			# We disconnected from networking
			update_enet_button_state("LEFT-NETWORK")
			update_game_button_state("CLEAR")
			status_message_label.text = "Disconnected..."
		1:
			# We became the host/server peer
			status_message_label.text = "Connected as Server/Host..."
			update_enet_button_state("JOINED-NETWORK")
			update_game_button_state("START")
			
		_:
			# We bacame a client peer
			update_enet_button_state("JOINED-NETWORK")
			status_message_label.text = "Connected as Client..."


func _on_host_button_pressed() -> void:
	# Start multiplayer_peer networking
	status_message_label.text = "Starting Network..."
	Network.create_network()


func _on_join_button_pressed() -> void:
	status_message_label.text = "Joining Network..."
	Network.join_network()



func _on_start_game_button_pressed() -> void:
	#Levels.goto_scene.rpc("res://scenes/levels/test_level.tscn")
	#Levels.goto_scene.rpc("res://scenes/levels/level_1.tscn")
	Levels.goto_next_scene.rpc()



func _on_main_menu_button_pressed() -> void:
	GameState.change_game_state(GameState.GAME_STATES.MAIN_MENU)


func _on_leave_network_button_pressed() -> void:
	Network.remove_multiplayer_peer()
