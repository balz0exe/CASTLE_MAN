extends Node

func _physics_process(delta: float) -> void:
	if Game.get_player().has_boots:
		get_parent().interaction_coll.disabled = true
	else:
		get_parent().interaction_coll.disabled = false
