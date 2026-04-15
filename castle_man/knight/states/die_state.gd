#die_state.gd
extends PlayerState

var played = false

func enter(_prev_state):
	if state_machine.monitor:print("Entered Die State")
	player.animation.stop()

func exit():
	played = false
	if state_machine.monitor:print("Exited Die State")

func physics_update(_delta):
	player.velocity.x = 0

func update_animation():
	if !played:
		played = true
		player.velocity.y = -300
		player.animation.play("die")
		await player.animation.animation_finished
		Game.spawn_particle_oneshot("res://fx/particle_fx/enemy_death_particles.tscn", player.animation)
		Game.fade_out_sprite(player.animation)
		await Game.wait_for_seconds(3)
		player.respawn()

func update_input():
	pass

func get_state_name():
	return "DieState"
