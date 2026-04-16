#roll_state.gd
extends PlayerState

var playing : bool = false

func enter(_prev_state):
	if state_machine.monitor:print("Entered Roll State")
	player.stamina -= player.roll_stam_cost
	Game.play_sfx_pitched(player.jump_sfx, Game.sfx_volume, player, 0.8)
	player.velocity.x = player.roll_distance * 10 * Input.get_axis("ui_left", "ui_right")

func exit():
	player.invincible = false
	playing = false
	if state_machine.monitor:print("Exited Roll State")

func physics_update(delta):
	player.invincible = true
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
		player.velocity.x += Input.get_axis("ui_left", "ui_right") * (player.acceleration) * delta

func update_animation():
	if !playing:
		playing = true
		player.animation.play("roll")
		await player.animation.animation_finished
		if player.state_version != version:
			return
		if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
			state_machine.change_state("RunState")
		else:
			state_machine.change_state("IdleState")

func update_input():
	pass

func get_state_name():
	return "RollState"
