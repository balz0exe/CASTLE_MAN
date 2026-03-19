extends ColorRect

@onready var player = Game.get_player()

func _process(_delta: float) -> void:
	size.x = player.stamina * 2
