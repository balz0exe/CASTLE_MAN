extends Powerup

func _ready() -> void:
	super()
	player.can_air_throw = true
	print("added air throw to player")
