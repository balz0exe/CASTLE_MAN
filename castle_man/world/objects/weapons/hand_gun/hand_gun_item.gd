extends Node

@onready var parent: Area2D = get_parent()

func on_thrown():
	Game.play_sfx(load("res://fx/audio_fx/gun_shot.wav"), Game.sfx_volume, parent)
	for i in range(3):
		Game.spawn_particle_oneshot("res://fx/particle_fx/barrel_flash.tscn", parent, Game.get_player().direction * Vector2(15,0), Color.YELLOW)
		Game.get_player().global_position.x += -Game.get_player().direction * 2
		await Game.wait_for_seconds(0.1)
