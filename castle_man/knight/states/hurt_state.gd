#hurt_state.gd
extends PlayerState

func enter(_prev_state):
	if state_machine.monitor:print("Entered Hurt State")
	Game.play_sfx(player.hurt_sfx, Game.sfx_volume, player)
	player.knocked_back = true
	player.recovery_timer = player.knockback_recovery

func retrigger():
	Game.play_sfx(player.hurt_sfx, Game.sfx_volume, player)
	player.knocked_back = true
	player.recovery_timer = player.knockback_recovery

func exit():
	player.knockback_force = 0
	player.knocked_back = false
	if state_machine.monitor:print("Exited Hurt State")
	player.velocity.x = 0
	player.flip_h = !player.flip_h

func physics_update(_delta):
	if player.hits_taken > 1:
		player.disarm()
		player.invincible_timer = player.invincible_time
		player.invincible = true
	player.velocity.x = player.knockback_force

func update_animation():
	player.animation.play("fall")

func update_input():
	if player.recovery_timer <= 0 and player.knocked_back:
		player.state_machine.change_state("IdleState")

func get_state_name():
	return "HurtState"
