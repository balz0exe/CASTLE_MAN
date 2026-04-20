extends Powerup

func _ready() -> void:
	super()
	player.can_double_jump = true
	print("added double jump to player")
