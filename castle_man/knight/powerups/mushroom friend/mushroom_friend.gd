extends Powerup

func _ready() -> void:
	super()
	var friend = load("res://enemies/scenes/mushroom.tscn")
	friend = Game.spawn_object(friend, Game.get_player().global_position + Vector2(25, -5))
	Game.spawn_particle_oneshot("res://fx/particle_fx/ground_pound_particles.tscn", friend, Vector2(0, 5), Color.DIM_GRAY)
	friend.friendly = true
	
