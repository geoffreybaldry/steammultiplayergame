extends Area2D
class_name SpawnPoint

var occupying_players: Array[String]


func is_available() -> bool:
	return occupying_players.is_empty()


func _on_body_entered(body: Node2D) -> void:
	Log.pr("Spawn point " + self.name + " area entered by body : " + body.name)
	
	occupying_players.append(body.name)
	

func _on_body_exited(body: Node2D) -> void:
	Log.pr("Spawn point " + self.name + " area exited by body : " + body.name)
	
	if occupying_players.has(body.name):
		occupying_players.erase(body.name)
