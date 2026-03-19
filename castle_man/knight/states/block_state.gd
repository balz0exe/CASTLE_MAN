#block_state.gd
extends PlayerState

func enter(_prev_state):
	if !player.has_weapon:
		state_machine.change_state("IdleState")
		return
	if state_machine.monitor:print("Entered Block State")
	player.animation.play("block")
	await player.animation.animation_finished
	player.parry = false
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
	if Input.is_action_pressed("attack"):
		state_machine.change_state("AttackState")

func get_state_name():
	return "BlockState"
