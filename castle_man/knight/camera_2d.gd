extends Camera2D

@onready var player = get_parent()

var death_pos: Vector2
var _offset: Vector2

func _on_knight_player_died() -> void:
	death_pos = global_position
	global_position = death_pos

func _on_knight_player_respawned() -> void:
	pass

func _set_offset(value: Vector2):
	_offset = value

func _physics_process(delta: float) -> void:
	if player.dead:
		global_position = death_pos
	else:
		offset = offset.lerp(_offset, 6 * delta)
		global_position = global_position.lerp(player.global_position + Vector2(player.direction * 4, clamp(player.velocity.y * 0.3, 30, 100)*1.4-30), 4 * delta)
