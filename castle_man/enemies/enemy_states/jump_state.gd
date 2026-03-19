#jump_state.gd
extends EnemyState

func enter(_prev_state):
	if !player.is_on_floor():
		player.state_machine.change_state("IdleState")
	if state_machine.monitor:print("Entered Jump State")
	if player.velocity.y > 0: player.velocity.y = 0
	player.velocity.y = player.jump_strength

func exit():
	if state_machine.monitor:print("Exited Jump State")

func physics_update(delta):
	player.velocity.x += player.acceleration * player.direction * delta
	
func update_animation():
	if not player.animation.animation.contains("attack") and not player.animation.animation.contains("block") and not player.animation.animation.contains("jump"):
		player.animation.play("jump")
	
func update_input():
	pass

func get_state_name():
	return "JumpState"
