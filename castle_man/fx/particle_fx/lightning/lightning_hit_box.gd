extends HitBox

#func _on_area_entered(hurt_box: Area2D):
	#if not hurt_box is HurtBox:
		#return
	#print("!!!")
	#await Game.wait_for_seconds(0.1)
	#Game.spawn_particle_oneshot("res://fx/particle_fx/lightning/Sparks.tscn", hurt_box.get_parent(), Vector2.ZERO, null, false)
