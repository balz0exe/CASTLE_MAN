#die_state.gd
extends PlayerState

var played = false

func enter(_prev_state):
	if state_machine.monitor:print("Entered Die State")
	player.animation.stop()
	Game.play_sfx(player.hurt_sfx, Game.sfx_volume, player)

func exit():
	played = false
	if state_machine.monitor:print("Exited Die State")

func physics_update(_delta):
	pass

func update_animation():
	if !played:
		played = true
		player.velocity.y = -300
		player.animation.play("die")
		await player.animation.animation_finished
		player.coll.disabled = true
		while player.position.y < player.get_viewport_rect().size.y:
			player.animation.animation = "die"
			player.animation.frame = 3
			await get_tree().process_frame
			player.rotation += 0.03
		await Game.wait_for_seconds(3)
		player.respawn()

func update_input():
	pass

func get_state_name():
	return "DieState"
