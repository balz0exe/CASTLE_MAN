#fall_state.gd
extends EnemyState

func enter(_prev_state):
	if state_machine.monitor:print("Entered Fall State")

func exit():
	player.animation.stop()
	if state_machine.monitor:print("Exited Fall State")

func physics_update(delta):
	if player.is_on_floor():
		state_machine.change_state("IdleState")
	if (player.direction == -1 or player.direction == 1) and player.state_machine.current_state.get_state_name() == "RunState":
		player.velocity.x += player.acceleration * player.direction * delta
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, 150 * delta)

func update_animation():
	if not player.animation.animation == "roll" and not player.animation.animation.contains("attack") and not player.animation.animation.contains("block"):
		player.animation.play("fall")

func update_input():
	pass

func get_state_name():
	return "FallState"
