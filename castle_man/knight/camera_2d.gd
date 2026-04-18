extends Camera2D

@onready var player = get_parent()

var death_pos: Vector2

func _on_knight_player_died() -> void:
	death_pos = global_position
	global_position = death_pos

func _on_knight_player_respawned() -> void:
	pass

func _physics_process(delta: float) -> void:
	if player.dead:
		global_position = death_pos
	else:
		global_position = global_position.lerp(player.global_position + Vector2(player.direction * 15, 5), 6 * delta)
