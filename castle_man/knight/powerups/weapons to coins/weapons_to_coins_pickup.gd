extends Node

func _physics_process(_delta: float) -> void:
	Game.animate_spining(get_parent().sprite)
