extends Node

func _ready() -> void:
	get_parent().sprite.scale = Vector2.ONE*1.5
	get_parent().sprite.offset = Vector2(0,-5)

func _physics_process(_delta: float) -> void:
	Game.animate_spining(get_parent().sprite)
