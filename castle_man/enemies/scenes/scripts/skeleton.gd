extends Enemy

func damage_particles() -> void:
	Game.spawn_particle_oneshot("res://fx/particle_fx/blood_particles.tscn", self, Vector2(0, -5), Color(0.8, 1, 1))
