extends Powerup

func _ready() -> void:
	super()
	player.hurt_factor += player.hurt_factor * -0.2
	print("increased player hurt factor to " + str(player.hurt_factor))
