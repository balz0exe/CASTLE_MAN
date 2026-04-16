extends Powerup

func on_ground_pound():
	Game.spawn_explosion(player, 50, 30)
