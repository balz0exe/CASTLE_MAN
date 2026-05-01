#throw_state.gd
extends EnemyState

var _delta

func enter(_prev_state):
	if state_machine.monitor:print("Entered Throw State")
	player.combo_counter = 0

func exit():
	fired = false
	player.ENEMY_AI.throw_timer = player.throw_delay
	print("set throw timer: "+str(player.ENEMY_AI.throw_timer))
	if state_machine.monitor:print("Exited Throw State")

func physics_update(delta):
	_delta = delta
	if player.velocity.y > 0:
		player.velocity.y = 0
	player.velocity.x = move_toward(player.velocity.x, 0, player.friction * 100 * delta)

var fired = false
func update_animation():
	if player.ranged_type:
		player.animation.play("attack 1")
	else:
		player.animation.play("attack 3")
	await player.animation.animation_finished
	if version != player.state_version:
		return
	if player.weapon and !player.ranged_type: player.weapon.throw(_delta)
	elif player.ranged_type:
		if !fired:
			fired = true
			player.fire()
	state_machine.change_state("IdleState")


func update_input():
	pass

func get_state_name():
	return "ThrowState"
