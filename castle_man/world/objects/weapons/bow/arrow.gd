extends Node

var hit = false

func on_hit(target):
	if !target.is_class(CharacterBody2D):
		return
	if !hit:
		hit = true
		get_parent().sleeping = true
		await get_tree().process_frame
		get_parent().queue_free()
		if Game.get_player().exploding_arrows:
			Game.spawn_explosion(target)
