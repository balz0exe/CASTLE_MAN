#throw_state.gd
extends PlayerState

func enter(_prev_state):
	if state_machine.monitor:print("Entered Throw State")
	player.combo_counter = 0

func exit():
	if state_machine.monitor:print("Exited Throw State")

func physics_update(delta):
	if player.velocity.y > 0:
		player.velocity.y -= 10
	player.velocity.x = move_toward(player.velocity.x, 0, player.friction * 100 * delta)
	if Input.get_axis("ui_left", "ui_right") == 1:
		player.flip_h = false
	if Input.get_axis("ui_left", "ui_right") == -1:
		player.flip_h = true
	if Input.is_action_just_released("attack"):
		if player.weapon: player.weapon.throw()

func update_animation():
	player.animation.play("throw")
	if Input.is_action_pressed("attack"):
		player.animation.frame = 0

func update_input():
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.velocity.y = player.jump_strength
	if Input.is_action_just_released("jump"):
		player.velocity.y = 0
	if Input.is_action_just_pressed("ui_down"):
		state_machine.change_state("IdleState")
	if Input.is_action_just_pressed("roll"):
		state_machine.change_state("RollState")

func get_state_name():
	return "ThrowState"
