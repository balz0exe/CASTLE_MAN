extends Powerup

func _ready() -> void:
	super()
	for g in range(5):
		var goblin = Game.spawn_object(load("res://enemies/scenes/goblin.tscn"), Vector2(randi_range(-125, 125), 110))
		Game.spawn_particle_oneshot("res://fx/particle_fx/smoke.tscn", goblin)
		goblin.friendly = true
		await get_tree().process_frame
		print("spawned goblin #: "+str(g+1)+" @: "+str(goblin.global_positioin))
		randomize()
