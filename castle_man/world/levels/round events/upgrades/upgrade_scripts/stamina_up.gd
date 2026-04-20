extends Powerup

func _ready() -> void:
	super()
	player.max_stamina += 5
	print("added 5 max_stamina to player")
