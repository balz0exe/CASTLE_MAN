extends Enemy

func damage_particles() -> void:
	Game.spawn_particle_oneshot("res://fx/particle_fx/blood_particles.tscn", self, Vector2(0, -5), Color(0.5, 1, 0.3))

func on_attacked() -> void:
	@warning_ignore("integer_division")
	if is_on_floor(): velocity.y = jump_strength/2
	velocity.x += 50 * direction

func secondary_process() -> void:
	if state_machine.current_state.get_state_name() == "RunState" and is_on_floor():
		Game.animate_bouncing(animation)

func on_fired(projectile) -> void:
	if !friendly: projectile.ignore_enemies = true
	else: projectile.ignore_player = true
	projectile.ignore_objects = true
	projectile.behavior_node.damage = 6
	projectile.behavior_node.radius = 15
	projectile.apply_impulse(Vector2(0, -150))

func take_damage(damage, from: Node2D, knockback: float = 10, auto_kill: bool = false):
	if !dead:
		if from != null:
			if from.has_method("explode"):
				return
		if parry:
			from.parried(self)
			return
		health -= damage
		if auto_kill:
			health =0
		damage_particles()
		await get_knockback_direction(from)
		if state_machine.current_state.get_state_name() == "HurtState":
			state_machine.current_state.retrigger()
		else:
			state_machine.change_state("HurtState")
		if from == null:
			return
		knockback_force = 15 * knockback * knock_back_direction.x * knockback_factor
