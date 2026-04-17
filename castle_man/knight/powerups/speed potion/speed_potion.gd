extends Powerup

var timer: float

func _ready() -> void:
	super()
	timer = 5
	var original_maxspeed = player.prev_speed
	while timer > 0:
		player.speed_potion = 2.5
		await get_tree().process_frame
	player.speed_potion = 1
	queue_free()

func _physics_process(delta: float) -> void:
	timer -= 1 * delta
