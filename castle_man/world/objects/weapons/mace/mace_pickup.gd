extends Node

func on_thrown(delta):
	if Game.get_player().thors_hammer and get_parent().from.is_in_group("player"):
		#USE RANGED TO MAKE ENEMIES IGNORE
		get_parent().ranged = true
		get_parent().interaction_coll.disabled = true
		get_parent().apply_impulse(Vector2((get_parent().direction*500), -25))
		Game.get_player().invincible_timer = 2
		Game.get_player().invincible = true
		while get_parent().linear_velocity.length() == 0:
			await get_tree().process_frame
		while get_parent().linear_velocity.length() > 5:
			Game.get_player().global_position = lerp(Game.get_player().global_position, get_parent().global_position, 5*delta)
			await get_tree().process_frame
		Game.spawn_particle_oneshot("res://fx/particle_fx/lightning/lightning.tscn", get_parent(), Vector2(10, 0))        
		Game.play_sfx(load("res://fx/audio_fx/lightning_strike.wav"), Game.sfx_volume, get_parent())
		var timer = 5
		while timer > 0:
			timer -= delta
			await get_tree().process_frame
		get_parent().interaction_coll.disabled = false
	
