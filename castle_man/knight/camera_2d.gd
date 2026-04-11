extends Camera2D

@onready var player = get_parent()

var death_pos: Vector2

func _on_knight_player_died() -> void:
	death_pos = global_position
	top_level =  true
	global_position = death_pos

func _on_knight_player_respawned() -> void:
	global_position = Vector2.ZERO
	top_level =  false

func _physics_process(_delta: float) -> void:
	#if player.state_machine.current_state.get_state_name() != "HurtState":
	Game.tween_camera_position(self, Vector2(player.direction * 15, 5))

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_LEFT:
				if zoom < Vector2(5, 5): zoom += Vector2(0.05, 0.05)
			if event.button_index == MOUSE_BUTTON_RIGHT:
				if zoom > Vector2(0.5, 0.5): zoom -= Vector2(0.05, 0.05)
