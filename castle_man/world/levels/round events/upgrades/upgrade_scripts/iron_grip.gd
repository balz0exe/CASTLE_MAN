extends Powerup

func _ready() -> void:
	super()
	player.iron_grip = true
	print("added iron grip to player")
