extends RoundEvent

func _ready() -> void:
	Game.fade_out_sprite(Game.get_player().light, 0.5 , 0.3)
	var tween = create_tween()
	tween.tween_property(get_tree().get_first_node_in_group("LevelScene").canvas, "color", Color.BLACK, 0.5)
	
func clean_up():
	Game.fade_in_sprite(Game.get_player().light)
	var _tween = create_tween()
	_tween.tween_property(get_tree().get_first_node_in_group("LevelScene").canvas, "color", Color.from_rgba8(108, 108, 108), 0.5)
	while get_tree().get_first_node_in_group("LevelScene").canvas.color != Color.from_rgba8(108, 108, 108):
		await get_tree().process_frame
	queue_free()

func _physics_process(_delta: float) -> void:
	pass
