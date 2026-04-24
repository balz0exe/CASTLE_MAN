extends Node

var hit = false

func _process(_delta: float) -> void:
	await Game.wait_for_seconds(0.5)
	print(get_parent().linear_velocity.x)

func on_hit(target):
	if !target.is_class("CharacterBody2D"):
		return
	if !hit:
		hit = true
		get_parent().sleeping = true
		await get_tree().process_frame
		get_parent().queue_free()
		if Game.get_player().exploding_arrows:
			Game.spawn_explosion(target, 40, 20, 5, true)
