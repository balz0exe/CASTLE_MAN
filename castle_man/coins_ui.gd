extends Sprite2D

@onready var label = $Label

var wait: bool = false

func _process(_delta: float) -> void:
	if Game.get_level().name == "TitleScreen":
		visible = false
	else:
		visible = true
		animate()
	if Game.get_player() != null:
		label.text = ": " + str(Game.get_player().coins)

func animate() -> void:
	if wait:
		return
	wait = true
	frame = (frame + 1) % 8  # wraps 0–7 cleanly
	await get_tree().create_timer(0.2).timeout
	wait = false
