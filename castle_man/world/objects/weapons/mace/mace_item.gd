extends Node

func on_hit(target):
	print("1")
	if target.is_in_group("enemies") and Game.get_player().thors_hammer:
		print("2")
		var lightning = Game.spawn_particle_oneshot("res://fx/particle_fx/lightning/lightning.tscn", target)
		lightning.time = 2
