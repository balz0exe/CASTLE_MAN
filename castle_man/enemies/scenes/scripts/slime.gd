extends Enemy

func damage_particles() -> void:
	Game.spawn_particle_oneshot("res://fx/particle_fx/blood_particles.tscn", self, Vector2(0, -5), Color(0, 1, 0.2))

func on_attacked() -> void:
	@warning_ignore("integer_division")
	if is_on_floor(): velocity.y = jump_strength/2
	velocity.x += 50 * direction

func on_died(_enemy) -> void:
	@warning_ignore("integer_division")
	velocity.y = int(jump_strength/2)
