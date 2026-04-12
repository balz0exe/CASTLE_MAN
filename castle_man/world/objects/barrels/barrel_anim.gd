extends AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	if get_parent().rotation_degrees < -90 or get_parent().rotation_degrees > 90:
		flip_v = true
		position.y = 1
	else:
		flip_v = false
		position.y = 0
		
