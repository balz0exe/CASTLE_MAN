extends Powerup

func _ready() -> void:
	super()
	player.damage_factor += 0.2
	print("increased player damage factor to " + str(player.damage_factor))
