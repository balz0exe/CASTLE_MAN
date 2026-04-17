extends Node

func _ready() -> void:
	get_parent().sprite.scale.y = 0.6
	get_parent().sprite.modulate = Color.SKY_BLUE
