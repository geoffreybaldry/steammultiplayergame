extends Node

const TILE_SIZE_PX: int = 32
const HALF_TILE_SIZE_PX: int = 16

var spawn_points = {}


func register(this_spawn_point: SpawnPoint, this_id: String) -> void:
	if not spawn_points.has(this_id):
		spawn_points[this_id] = this_spawn_point
		Log.pr("Registered Spawn Point : " + str(this_id))
		
	
func get_free_spawn_point_position():
	for spawn_point_id: String in spawn_points.keys():
		if spawn_points[spawn_point_id].is_available():
			# Mark this spawn point temporarily as selected
			spawn_points[spawn_point_id].select() 
			return spawn_points[spawn_point_id].global_position + Vector2(HALF_TILE_SIZE_PX, HALF_TILE_SIZE_PX)
			
	return null


func has_free_spawn_point() -> bool:
	for spawn_point_id: String in spawn_points.keys():
		if spawn_points[spawn_point_id].is_available():
			return true
	return false
	

func clear_spawn_points() -> void:
	spawn_points.clear()
