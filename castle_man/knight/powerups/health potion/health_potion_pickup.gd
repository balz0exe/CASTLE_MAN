extends Node

func _ready() -> void:
	get_parent().sprite.modulate = Color.RED
	get_parent().sprite.scale.y = 0.6

func _process(_delta: float) -> void:
	if Game.get_player().health < Game.get_player().max_health - 5:
		get_parent().interaction_coll.disabled = true
	else:
		get_parent().interaction_coll.disabled = false
