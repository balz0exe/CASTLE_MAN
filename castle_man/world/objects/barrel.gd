extends WorldObject

func on_broken() -> void:
	Game.play_sfx(load("res://fx/audio_fx/u_kir90yky9e-woodhitsfx-390569.mp3"), Game.sfx_volume - 8, self)
