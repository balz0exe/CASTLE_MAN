#run_state.gd
extends PlayerState

var is_breaking: bool = false

func enter(_prev_state):
	if Input.get_axis("ui_left", "ui_right") == 0:
		state_machine.change_state("IdleState")
		return
	if state_machine.monitor:print("Entered Run State")
	sfx()

func exit():
	player.animation.speed_scale = 1
	if state_machine.monitor:print("Exited Run State")

func sfx() -> void:
	while true:
		if  version == player.state_version:
			Game.play_sfx(player.run_sfx, Game.sfx_volume - 18, player)
			if player.sprint:
				await Game.wait_for_seconds(0.3)
			else:
				await Game.wait_for_seconds(0.4)
			if version != player.state_version:
				break
		else:
			break

func physics_update(delta):
	if Input.get_axis("ui_left", "ui_right") == 0:
		state_machine.change_state("IdleState")
	if not is_breaking:
		player.velocity.x += player.acceleration * Input.get_axis("ui_left", "ui_right") * delta
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.friction * 100 * delta)

func update_animation():
	if player.velocity.x > player.max_speed + 10:
		player.animation.speed_scale = 2.0
	else:
		player.animation.speed_scale = 1.0
	if player.animation.animation == "break" and not (player.animation.animation == "break" and player.animation.frame == 2):
		return
	if not is_breaking or (player.animation.animation == "break" and player.animation.frame == 2):
		player.animation.play("run")
	else:
		if !Input.get_axis("ui_left", "ui_right") == 0: player.animation.play("break")

func update_input():
	if not (Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right")) or Input.get_axis("ui_left", "ui_right") == 0:
		state_machine.change_state("IdleState")
	if Input.is_action_pressed("sprint"):
		player.sprint = true
	else:
		player.sprint = false
	if (Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right")):
		if player.velocity.x > 0 and Input.is_action_pressed("ui_left"):
			is_breaking = true
		elif player.velocity.x < 0 and Input.is_action_pressed("ui_right"):
			is_breaking = true
		else:
			is_breaking = false
	if Input.is_action_just_pressed("jump") and (player.is_on_floor() or player.coyote_timer > 0.0):
		state_machine.change_state("JumpState")
	if Input.is_action_just_pressed("roll"):
		state_machine.change_state("RollState")
	if Input.is_action_just_pressed("attack") and player.has_weapon and player.combo_reset_timer <= 0.0:
		state_machine.change_state("AttackState")
func get_state_name():
	return "RunState"
