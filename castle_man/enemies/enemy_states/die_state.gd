#die_state.gd
extends EnemyState

func enter(_prev_state):
	if state_machine.monitor:print("Entered Die State")
	player.animation.stop()
	Game.play_sfx(player.hurt_sfx, Game.sfx_volume, player)

func exit():
	if state_machine.monitor:print("Exited Die State")

func physics_update(_delta):
	pass

var played = false

func update_animation():
	if !played:
		played = true
		player.animation.play("die")
		await player.animation.animation_finished
		player.coll.disabled = true
		player.velocity.y += player.jump_strength
		while player.position.y < (player.get_viewport_rect().size.y - 150):
			player.animation.animation = "die"
			player.animation.frame = 3
			await get_tree().process_frame
			player.rotation += 0.1
		player.queue_free()

func update_input():
	pass

func get_state_name():
	return "DieState"
