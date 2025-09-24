extends Node2D

@export var orbit_speed: float = 1.0 # Radians per second for orbit speed

func _process(delta):
	pass
	# Rotate the pivot around its origin
	#rotation += orbit_speed * delta
	
	# Ensure rotation stays within 0 to 2*PI radians (360 degrees)
	# Use rotation_degrees for easier degree-based rotation if preferred
	# rotation_degrees += orbit_speed_degrees * delta
	# rotation_degrees = wrapf(rotation_degrees, 0.0, 360.0)

	#look_at(get_global_mouse_position())
