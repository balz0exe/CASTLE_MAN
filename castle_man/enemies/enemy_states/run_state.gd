#run_state.gd
extends EnemyState

var is_breaking: bool = false

func enter(_prev_state):
	if state_machine.monitor:print("Entered Run State")

func exit():
	player.animation.stop()
	if state_machine.monitor:print("Exited Run State")

func physics_update(delta):
	if player.direction != sign(player.velocity.x) and player.velocity.x != 0:
		is_breaking = true
	else:
		is_breaking = false
	if not is_breaking:
		player.velocity.x += player.acceleration * player.direction * delta
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.friction * 100 * delta)

func update_animation():
	if not is_breaking:
		player.animation.play("run")
	else:
		player.animation.play("break")

func update_input():
	pass

func get_state_name():
	return "RunState"
