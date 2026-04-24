extends ColorRect

@onready var player = Game.get_player()

func _process(_delta: float) -> void:
	if Game.get_level().name == "TitleScreen":
		visible = false
	else:
		visible = true
	if Game.get_player():
		player = Game.get_player()
		size.x = player.stamina * 2
