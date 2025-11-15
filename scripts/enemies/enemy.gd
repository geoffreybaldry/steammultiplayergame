@tool
extends CharacterBody2D
class_name Enemy

@export var speed = 10.0
@export var acceleration = 300.0
@export var deceleration = 300.0
@export var sensor_radius = 30.0
@export var min_sensor_radius = 10.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer
#@onready var nearby_player_label: Label = $nearby_player_label

#var target_motion: Vector2 = Vector2.ZERO


#func _get_rollback_state_properties() -> Array:
	#return [
		#"position",
		#"velocity"
	#]

#func _get_interpolated_properties() -> Array:
	#return [
		#"position"
	#]


func _rollback_tick(delta, _tick, _is_fresh: bool):
	pass


func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return


func apply_animation() -> void:
	pass

	
#func _find_nearby_player() -> Node2D:
	#var players := get_tree().get_nodes_in_group(&"Players")
	#if players.is_empty():
		#return null
		#
	#var sensor_radius_squared := pow(SENSOR_RADIUS, 2.0)
	#var min_radius_squared := pow(MIN_RADIUS, 2.0)
#
	#var closest_player: Node2D = null
	#var closest_distance := INF
	#for player in players:
		#var distance := global_position.distance_squared_to(player.global_position)
#
		#if distance >= sensor_radius_squared or distance <= min_radius_squared:
			#continue
#
		#if distance < closest_distance:
			#closest_distance = distance
			#closest_player = player
#
	#return closest_player
