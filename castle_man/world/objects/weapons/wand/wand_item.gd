extends Node

var fire: CPUParticles2D

func _ready() -> void:
	if get_parent().owner_player.is_in_group("enemies"):
		get_parent().throwable = false
		return
	fire = load("res://fx/particle_fx/fire_2.tscn").instantiate()
	get_parent().add_child(fire)
	fire.position = Vector2(15,0)
	fire.speed_scale = 1
	fire.color = Color(1, 0, 0.2, 0.5)
	fire.get_child(0).color = Color(1, 0.0, 0.2, 0.5)
	fire.lifetime = 0.1
	
