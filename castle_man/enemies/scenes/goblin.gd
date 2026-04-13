extends Enemy

func damage_particles() -> void:
	Game.spawn_particle_oneshot("res://fx/particle_fx/blood_particles.tscn", self, Vector2(0, -5), Color(0.5, 1, 0.3, 0.5))

func on_attacked() -> void:
	if is_on_floor(): velocity.y = jump_strength
	velocity.x += 50 * direction

func secondary_process() -> void:
	if state_machine.current_state.get_state_name() == "RunState" and is_on_floor():
		velocity.y = jump_strength/4
