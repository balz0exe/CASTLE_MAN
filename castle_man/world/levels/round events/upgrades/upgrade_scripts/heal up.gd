extends Powerup

func _ready() -> void:
	super()
	while player.health < player.max_health:
		player.health += 1
		await get_tree().process_frame
	print("fully healed player")
