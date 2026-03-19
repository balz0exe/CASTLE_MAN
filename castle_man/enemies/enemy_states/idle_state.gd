#idle_state.gd
extends EnemyState

func enter(_prev_state):
	if state_machine.monitor:print("Entered Idle State")

func exit():
	player.animation.stop()
	if state_machine.monitor:print("Exited Idle State")

func physics_update(delta):
	player.velocity.x = move_toward(player.velocity.x, 0, player.friction * 100 * delta)

func update_animation():
	if not player.animation.is_playing():
		player.animation.play("idle")

func update_input():
	pass

func get_state_name():
	return "IdleState"
