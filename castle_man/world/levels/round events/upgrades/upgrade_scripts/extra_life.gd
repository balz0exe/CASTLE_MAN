extends Powerup

func _ready() -> void:
	super()
	player.lives += 1
	print("added 1 life to player")
