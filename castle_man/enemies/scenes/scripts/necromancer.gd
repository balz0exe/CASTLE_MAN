extends Enemy

var skeletons: Array[Enemy]

func damage_particles() -> void:
	Game.spawn_particle_oneshot("res://fx/particle_fx/blood_particles.tscn", self, Vector2(0, -5), Color(0.5, 0, 1))

func on_fired(projectile) -> void:
	skeletons.append(projectile)
	Game.spawn_particle_oneshot("res://fx/particle_fx/necromancer_magic.tscn", projectile, Vector2(0, -5))

func on_died(_enemy) -> void:
	for s in skeletons:
		if s != null:
			s.take_damage(s.health, s)
