extends RoundEvent

func _ready() -> void:
	var tween = create_tween()
	tween.tween_property(get_tree().get_first_node_in_group("LevelScene").canvas, "color", Color.BLACK, 3)
	for i in range(20):
		var firefly = load("res://world/levels/round events/darkness/firefly.tscn")
		firefly = firefly.instantiate()
		Game.add_child(firefly)
	
func clean_up():
	var _tween = create_tween()
	_tween.tween_property(get_tree().get_first_node_in_group("LevelScene").canvas, "color", Game.COLOR, 3)
	while get_tree().get_first_node_in_group("LevelScene").canvas.color != Game.COLOR:
		await get_tree().process_frame
	queue_free()

func _physics_process(_delta: float) -> void:
	pass
