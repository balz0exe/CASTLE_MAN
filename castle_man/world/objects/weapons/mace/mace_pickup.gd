extends Node

func on_thrown():
	if Game.get_player().thors_hammer and get_parent().from.is_in_group("player"):
		Game.spawn_particle_oneshot("res://fx/particle_fx/lightning/lightning.tscn", get_parent())
	
