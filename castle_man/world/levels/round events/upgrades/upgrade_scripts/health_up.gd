extends Powerup

func _ready() -> void:
	super()
	var original_health = player.max_health
	player.max_health += 5
	player.health += player.max_health * (player.max_health/original_health)
	print("added 5 max_health to player")
