extends Powerup

var timer

func _ready() -> void:
	super()
	player.connect("hit", on_hit)
	timer = 20
	while timer > 0:
		await get_tree().process_frame
	player.has_boots = false
	queue_free()

func _process(delta: float) -> void:
	if timer > 0:
		timer -= delta

func on_hit(target):
	if target.is_in_group("enemies"):
		var lightning = Game.spawn_particle_oneshot("res://fx/particle_fx/lightning/lightning.tscn", target)
		lightning.time = 2
