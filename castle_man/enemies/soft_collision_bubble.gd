extends Area2D

var player
var colliders := []

func _ready() -> void:
	player = get_parent()

func _physics_process(_delta):
	for area in colliders:
		var current = player.state_machine.current_state.get_state_name()
		if !current == "HurtState":
			var direction = (player.global_position - area.global_position).normalized()
			if direction.y > 0: direction.y = 0
			if current == "AttackState":
				player.global_position += direction * 0.5
			elif current == "RunState":
				player.global_position += direction * 0.1
			else:
				player.global_position += direction * 2.0

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("soft collisions"):
		colliders.append(area)

func _on_area_exited(area: Area2D) -> void:
	if area in colliders:
		colliders.erase(area)
