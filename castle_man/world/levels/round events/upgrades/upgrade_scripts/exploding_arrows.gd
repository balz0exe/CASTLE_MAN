extends Powerup

func _ready() -> void:
	super()
	player.exploding_arrows = true
	print("added exploding arrows to player")
