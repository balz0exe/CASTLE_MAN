#throw_state.gd
extends EnemyState

func enter(_prev_state):
	if state_machine.monitor:print("Entered Throw State")
	player.combo_counter = 0

func exit():
	if state_machine.monitor:print("Exited Throw State")

func physics_update(delta):
	if player.velocity.y > 0:
		player.velocity.y = 0
	player.velocity.x = move_toward(player.velocity.x, 0, player.friction * 100 * delta)

func update_animation():
	player.animation.play("attack 3")
	await player.animation.animation_finished
	if version != player.state_version:
		return
	if player.weapon: player.weapon.throw()
	state_machine.change_state("IdleState")


func update_input():
	pass

func get_state_name():
	return "ThrowState"
