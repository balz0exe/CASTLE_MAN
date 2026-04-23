extends Powerup

func _ready() -> void:
	super()
	var friend = load("res://enemies/scenes/mushroom.tscn")
	friend = Game.spawn_object(friend, Game.get_player().global_position + Vector2(50, -5))
	friend.friendly = true
	
