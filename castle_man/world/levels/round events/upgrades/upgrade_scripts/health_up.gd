extends Powerup

func _ready() -> void:
	super()
	player.max_health += 5
	player.health += 5
	if player.health > player.max_health:
		player.health = player.max_health
	print("added 5 max_health to player and healed 5 health")
