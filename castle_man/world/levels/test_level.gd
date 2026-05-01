extends LEVEL

func _ready():
	super()
	player.exploding_arrows = true
	player.thors_hammer = true
	player.can_air_roll = true
	player.can_double_jump = true
	player.can_air_throw = true
	#player.hurt_factor = 0
	var enemies = Game.get_characters().filter(func(c):
		return c.is_in_group("enemies") and !c.friendly
	)
	for e in enemies:
		e.ENEMY_AI.enemy = Game.get_player()
