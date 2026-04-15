#idle_state.gd
extends PlayerState

func enter(_prev_state):
	if state_machine.monitor:print("Entered Idle State")
	player.sprint = false

func exit():
	if state_machine.monitor:print("Exited Idle State")

func physics_update(delta):
	player.velocity.x = move_toward(player.velocity.x, 0, player.friction * 100 * delta)

func update_animation():
	#if not player.animation.is_playing():
	player.animation.play("idle")

func update_input():
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
		state_machine.change_state("RunState")
	if Input.is_action_just_pressed("jump") and (player.is_on_floor() or player.coyote_timer > 0.0):
		state_machine.change_state("JumpState")
	if Input.is_action_just_pressed("attack") and player.has_weapon and player.combo_reset_timer <= 0.0:
		state_machine.change_state("AttackState")

func get_state_name():
	return "IdleState"
