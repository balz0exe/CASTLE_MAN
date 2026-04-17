extends Powerup

var timer: float

func _ready() -> void:
	super()
	timer = 10
	var original_maxspeed = player.prev_speed
	player.prev_speed = player.prev_speed * 2.5
	while timer > 0:
		await get_tree().process_frame
	player.prev_speed = original_maxspeed
	queue_free()

func _physics_process(delta: float) -> void:
	timer -= 1 * delta
