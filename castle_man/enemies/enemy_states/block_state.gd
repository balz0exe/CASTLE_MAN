#block_state.gd
extends EnemyState

func enter(_prev_state):
	if state_machine.monitor:print("Entered Block State")
	player.animation.play("block")
	await player.animation.animation_finished
	player.parry = false
	if version != player.state_version:
		return
	state_machine.change_state("IdleState")

func exit():
	if state_machine.monitor:print("Exited Block State")

func physics_update(delta):
	player.velocity.x = move_toward(player.velocity.x, 0, player.friction * 100 * delta)
	if player.animation.frame == 1:
		player.parry = true

func update_animation():
	pass

func update_input():
	pass

func get_state_name():
	return "BlockState"
