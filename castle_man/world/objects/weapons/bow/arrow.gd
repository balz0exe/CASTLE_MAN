extends Node

var hit = false

func on_hit(target):
	if !hit:
		hit = true
		get_parent().sleeping = true
		Game.spawn_explosion(target, 80, 20)
		await get_tree().process_frame
		get_parent().queue_free()
