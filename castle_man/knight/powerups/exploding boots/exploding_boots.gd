extends Powerup

var timer: float

func on_ground_pound():
	Game.spawn_explosion(player, 50, 30)

func _ready() -> void:
	super()
	player.has_boots = true
	timer = 20
	var original_maxspeed = player.prev_speed
	while timer > 0:
		player.speed_potion = 2.5
		await get_tree().process_frame
	player.speed_potion = 1
	player.has_boots = false
	queue_free()
	
func _physics_process(delta: float) -> void:
	timer -= 1 * delta
