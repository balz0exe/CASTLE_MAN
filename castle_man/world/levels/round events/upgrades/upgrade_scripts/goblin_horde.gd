extends Powerup

func _ready() -> void:
	super()
	for g in range(5):
		var goblin = Game.spawn_object(load("res://enemies/scenes/goblin.tscn"), Vector2(-500, randi_range(-800, 800)))
		goblin.friendly = true
