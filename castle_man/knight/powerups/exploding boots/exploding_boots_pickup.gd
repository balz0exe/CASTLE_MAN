extends Node

func _physics_process(_delta: float) -> void:
	if Game.get_player().has_boots:
		pass
		#get_parent().interaction_coll.disabled = true
	else:
		get_parent().interaction_coll.disabled = false
