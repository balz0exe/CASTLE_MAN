extends RoundEvent

@onready var original_enemies = get_parent().enemies

var enemies = [
	{ name = "mushroom", scene = load("res://enemies/scenes/mushroom.tscn"), weight = 3, min_round = 1 },
	{ name = "fire sprout", scene = load("res://enemies/scenes/fire_sprout.tscn"), weight = 2, min_round = 1 },
	]

func _ready() -> void:
	await get_tree().process_frame
	get_parent().enemies = enemies
	var tween = create_tween()
	tween.tween_property(get_tree().get_first_node_in_group("LevelScene").canvas, "color", Color.GREEN, 3)
	
func clean_up():
	get_parent().enemies = original_enemies
	var _tween = create_tween()
	_tween.tween_property(get_tree().get_first_node_in_group("LevelScene").canvas, "color", Game.COLOR, 3)
	while get_tree().get_first_node_in_group("LevelScene").canvas.color != Game.COLOR:
		await get_tree().process_frame
	queue_free()

func _physics_process(_delta: float) -> void:
	pass
