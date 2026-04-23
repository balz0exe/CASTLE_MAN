extends Node

func on_thrown():
	if Game.get_player().thors_hammer:
		Game.spawn_particle_oneshot("res://fx/particle_fx/lightning.tscn", get_parent())
	
