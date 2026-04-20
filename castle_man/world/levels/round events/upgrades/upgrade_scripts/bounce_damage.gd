extends Powerup

func _ready() -> void:
	super()
	player.damage_on_bounce = true
	print("added bounce damage to player")
