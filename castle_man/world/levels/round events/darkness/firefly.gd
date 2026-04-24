extends Node2D

const LIGHT_NODE       := "light"
const SPEED            := 30
const WANDER_INTERVAL  := 1
const EDGE_MARGIN      := 30.0
const FADE_IN_DURATION := 2.2

var _target     : Vector2
var _move_timer : float = 0.0
var _light_node : Node2D


func _ready() -> void:
	_light_node = get_node(LIGHT_NODE)
	_pick_new_target()
	position = _target

	Game.fade_in_sprite(_light_node, FADE_IN_DURATION, 0.8)


func _process(delta: float) -> void:
	_move_timer -= delta
	if _move_timer <= 0.0:
		_pick_new_target()
	position = position.move_toward(_target, SPEED * delta)


func _get_camera_rect() -> Rect2:
	var cam := get_viewport().get_camera_2d()
	var center := cam.get_screen_center_position()
	var half := get_viewport().get_visible_rect().size / 2.0 / cam.zoom
	return Rect2(center - half + Vector2(EDGE_MARGIN, EDGE_MARGIN),
				 (half * 2) - Vector2(EDGE_MARGIN, EDGE_MARGIN) * 2)


func _pick_new_target() -> void:
	var r := _get_camera_rect()
	_target = Vector2(randf_range(r.position.x, r.end.x),
					  randf_range(r.position.y, r.end.y))
	_move_timer = randf_range(WANDER_INTERVAL * 0.5, WANDER_INTERVAL * 1.5)


func _pulse() -> void:
	var t := create_tween()
	t.tween_property(_light_node, "scale",
		Vector2.ONE * randf_range(0.085, 0.115), randf_range(1.2, 2.8))\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	_pulse()
