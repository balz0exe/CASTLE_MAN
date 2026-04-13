extends VisibleOnScreenEnabler2D

var player : CharacterBody2D

func _ready() -> void:
	player = Game.get_player()

func _process(delta: float) -> void:
	if player.dead:
		queue_free()
