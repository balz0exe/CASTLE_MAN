extends Enemy

func damage_particles() -> void:
	Game.spawn_particle_oneshot("res://fx/particle_fx/blood_particles.tscn", self, Vector2(0, -5), Color(0.5, 0.4, 0.5))

func on_attacked() -> void:
	velocity.y -= 150
	velocity.x += 50 * direction
	await animation.animation_finished
	Game.play_sfx_pitched(load("res://fx/audio_fx/player_landing.wav"),Game.sfx_volume + 6, self, 0.7, false)
