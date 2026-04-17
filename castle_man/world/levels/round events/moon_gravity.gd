extends RoundEvent

func _ready() -> void:
	Game.GRAVITY = 250
func clean_up():
	Game.GRAVITY = 800
