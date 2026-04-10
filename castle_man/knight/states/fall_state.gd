#fall_state.gd
extends PlayerState

func enter(_prev_state):
	if state_machine.monitor:print("Entered Fall State")

func exit():
	player.animation.stop()
	if state_machine.monitor:print("Exited Fall State")

func physics_update(delta):
	player.velocity.y += 1 * delta
	if player.is_on_floor():
		if Input.is_action_pressed("ui_down"):
			Game.play_sfx(load("res://fx/audio_fx/player_landing.wav"), Game.sfx_volume + 3, player)
			Game.spawn_particle_oneshot("res://fx/particle_fx/ground_pound_particles.tscn", player, Vector2(0, 5), Color.WHITE, false)
		if Input.get_axis("ui_left", "ui_right") != 0:
			state_machine.change_state("RunState")
		else:
			state_machine.change_state("IdleState")
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
		if Input.get_axis("ui_left", "ui_right") != 0 and Input.get_axis("ui_left", "ui_right") != sign(player.velocity.x):
			player.velocity.x = 0
		player.velocity.x += player.acceleration * Input.get_axis("ui_left", "ui_right") * delta
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, 150 * delta)
	if player.animation.animation == "duck":
		player.velocity = player.velocity * 1.02

func update_animation():
	if player.animation.animation == "duck" and player.animation.frame == 1:
		return
	if Input.is_action_pressed("ui_down"):
		player.animation.play("duck")
	elif not player.animation.animation == "roll" and not player.animation.animation.contains("block"):
		player.animation.play("fall")

func update_input():
	if Input.is_action_just_pressed("attack") and player.has_weapon and player.combo_reset_timer <= 0.0:
		state_machine.change_state("AttackState")
	if Input.is_action_pressed("roll") and player.can_air_roll and not player.has_air_rolled:
		player.velocity.y = -300
		player.has_air_rolled = true
		state_machine.change_state("RollState")
	if Input.is_action_just_pressed("jump") and player.can_double_jump and (not player.has_double_jumped):
		if not player.coyote_timer > 0:
			player.has_double_jumped = true
			player.has_air_rolled = false
		state_machine.change_state("JumpState")

func get_state_name():
	return "FallState"
