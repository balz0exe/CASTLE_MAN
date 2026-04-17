extends Powerup

func _ready() -> void:
	super()
	player.health += 10
	if player.health > player.max_health:
		player.health = player.max_health
	queue_free()
