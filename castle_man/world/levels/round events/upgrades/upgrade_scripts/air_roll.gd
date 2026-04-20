extends Powerup

func _ready() -> void:
	super()
	player.can_air_roll = true
	print("added air roll to player")
