extends Node

func _ready() -> void:
	get_parent().sprite.scale = get_parent().sprite.scale/2
	
