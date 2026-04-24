extends Powerup

func _ready() -> void:
	super()
	for g in range(5):
		var ran = [1, -1].pick_random()
		var goblin = Game.spawn_object(load("res://enemies/scenes/goblin.tscn"), Vector2(ran*700, 75))
		goblin.friendly = true
