#die_state.gd
extends EnemyState

func enter(_prev_state):
	if state_machine.monitor:print("Entered Die State")
	player.died.emit()
	player.animation.stop()
	Game.play_sfx(player.hurt_sfx, Game.sfx_volume, player)

func exit():
	if state_machine.monitor:print("Exited Die State")

func physics_update(_delta):
	pass

var played = false

func update_animation():
	if !played:
		played = true
		player.animation.play("die")
		await player.animation.animation_finished
		Game.spawn_particle_oneshot("res://fx/particle_fx/enemy_death_particles.tscn", player.animation)
		Game.fade_out_sprite(player.animation)

func update_input():
	pass

func get_state_name():
	return "DieState"
