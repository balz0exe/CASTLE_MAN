#roll_state.gd
extends EnemyState

func enter(_prev_state):
	if state_machine.monitor:print("Entered Roll State")
	if player.is_on_floor():
		player.velocity.x = player.roll_distance * 10 * player.direction
	player.animation.play("roll")
	await player.animation.animation_finished
	if version != player.state_version:
		return
	state_machine.change_state("IdleState")

func exit():
	if state_machine.monitor:print("Exited Roll State")

func physics_update(_delta):
	pass

func update_animation():
	pass

func update_input():
	pass

func get_state_name():
	return "RollState"
