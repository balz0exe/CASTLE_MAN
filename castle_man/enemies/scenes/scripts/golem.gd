extends Enemy

func damage_particles() -> void:
	Game.spawn_particle_oneshot("res://fx/particle_fx/blood_particles.tscn", self, Vector2(0, -5), Color(0.5, 0.4, 0.5))

func on_attacked() -> void:
	hit_box.coll.disabled = true
	while animation.frame < 2:
		await get_tree().process_frame
		if state_machine.current_state.get_state_name() != "AttackState":
			return
		velocity.x = 0
	velocity.y -= 200
	velocity.x += 80 * direction
	await animation.animation_finished
	Game.play_sfx_pitched(load("res://fx/audio_fx/player_landing.wav"),Game.sfx_volume + 6, self, 0.7, false)
	var p = Game.spawn_particle_oneshot("res://fx/particle_fx/ground_pound_particles.tscn", self, Vector2(0, 15), Color.WHITE, false)
	var e = Game.spawn_explosion(self, 50, basic_damage, 50, false, true)
	e.hit_pause = false
	p.scale = Vector2.ONE * 0.4
