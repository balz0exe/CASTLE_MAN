#jump_state.gd
extends PlayerState

func enter(_prev_state):
	if state_machine.monitor:print("Entered Jump State")
	if player.velocity.y > 0: player.velocity.y = 0
	Game.play_sfx(player.jump_sfx, Game.sfx_volume, player)
	player.velocity.y += player.jump_strength

func exit():
	if state_machine.monitor:print("Exited Jump State")

func physics_update(delta):
	if Input.is_action_pressed("jump") and player.velocity.y < 0:
		player.velocity.y -= 1.5 * delta
	if Input.is_action_just_released("jump") and player.velocity.y < 0: player.velocity.y = 0
	player.velocity.x += player.acceleration * Input.get_axis("ui_left", "ui_right") * delta
	
func update_animation():
	if not player.animation.animation.contains("attack") and not player.animation.animation.contains("block") and not player.animation.animation.contains("jump"):
		player.animation.play("jump")
	
func update_input():
	if Input.is_action_just_pressed("attack") and player.has_weapon and player.combo_reset_timer <= 0.0:
		state_machine.change_state("AttackState")
	if Input.is_action_just_pressed("jump") and player.can_double_jump and (not player.has_double_jumped):
		player.has_air_rolled = false
		player.has_double_jumped = true
		enter(null)
	if Input.is_action_pressed("roll") and player.can_air_roll and not player.has_air_rolled:
		player.velocity.y = -300
		player.has_air_rolled = true
		state_machine.change_state("RollState")


func get_state_name():
	return "JumpState"
