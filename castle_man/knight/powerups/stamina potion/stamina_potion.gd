extends Powerup

var timer: float

func _ready() -> void:
	super()
	timer = 5
	while timer > 0:
		if player.stamina < player.max_stamina:
			player.stamina += 1
		else:
			player.stamina = player.max_stamina
		await get_tree().process_frame
	queue_free()

func _physics_process(delta: float) -> void:
	timer -= 1 * delta
