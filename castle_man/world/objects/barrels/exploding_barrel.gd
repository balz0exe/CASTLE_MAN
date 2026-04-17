extends WorldObject

func on_broken() -> void:
	Game.play_sfx(load("res://fx/audio_fx/u_kir90yky9e-woodhitsfx-390569.mp3"), Game.sfx_volume - 8, self)
	Game.spawn_explosion(self, 80, 30)

func take_damage(damage, from: Node2D, knockback: float = 10):
	if !broken:
		var knock_back_direction = -sign(from.global_position - global_position)
		var knockback_force: Vector2 = 15 * knockback * knock_back_direction
		if knockback_force.y > 0: knockback_force.y = 0
		apply_impulse(knockback_force)
		if from.name == "Explosion":
			await Game.wait_for_seconds(0.5)
		if breakable:
			health -= damage
			if health < 0 or from.get_script().get_global_name():
				_break()
