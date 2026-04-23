extends Powerup

func _ready() -> void:
	super()
	player.roll_distance = 20
	print("added big roll to player")
