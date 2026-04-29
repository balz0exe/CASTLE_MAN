extends Powerup

func _ready() -> void:
	super()
	var sfx_path := "res://fx/audio_fx/collect_coin.wav"
	var already_playing := Game.get_player().get_children().any(func(c): 
		return c is AudioStreamPlayer and c.stream == load(sfx_path) and c.playing)
	if not already_playing:
		Game.play_sfx(load(sfx_path), Game.sfx_volume - 18, Game.get_player(), true, Vector2(0.8, 1.6))
	Game.get_player().coins += 1
	queue_free()
