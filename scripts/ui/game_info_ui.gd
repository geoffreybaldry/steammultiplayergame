extends Control

@onready var game_state_label: Label = $game_state_hbox/game_state_label
@onready var player_instances_text: RichTextLabel = $game_info_hbox/player_instances_vbox/player_instances_text
@onready var enemy_instances_text: RichTextLabel = $game_info_hbox/enemy_instances_vbox/enemy_instances_text
@onready var seated_players_list: RichTextLabel = $game_info_hbox/seated_players_vbox/seated_players_list
@onready var players_dict_list: RichTextLabel = $game_info_hbox/players_dict_vbox/players_dict_list
@onready var player_spawn_queue_text: RichTextLabel = $game_info_hbox/player_spawn_queue_vbox/player_spawn_queue_text


var entities: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	entities = get_tree().current_scene.find_child("entities")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	game_state_label.text = "GameState: : " + GameState.GAME_STATES.keys()[GameState.current_game_state]
	
	update_seated_players()
	update_players_dict_list()
	update_player_instances_list()
	update_enemy_instances_list()
	update_player_spawn_queue_list()


func update_player_spawn_queue_list() -> void:
	player_spawn_queue_text.text = ""
	
	for player_id: int in entities.player_queue:
		player_spawn_queue_text.text += str(player_id) + "\n"
		

func update_enemy_instances_list() -> void:
	enemy_instances_text.text = ""
	
	for enemy_instance in entities.enemy_instances.keys():
		enemy_instances_text.text += entities.enemy_instances[enemy_instance].id + "\n"


func update_player_instances_list() -> void:
	player_instances_text.text = ""
	
	for player_instance in entities.player_instances.keys():
		player_instances_text.text += str(player_instance) + "\n"



func update_players_dict_list() -> void:
	players_dict_list.text = ""
	
	for player in Network.players.keys():
		players_dict_list.text += str(player) + " - " + Network.players[player]["name"] + "\n"
		

func update_seated_players() -> void:
	seated_players_list.text = ""
	for peer_id: int in Network.seats:
		seated_players_list.text += str(peer_id) + "\n"
		
