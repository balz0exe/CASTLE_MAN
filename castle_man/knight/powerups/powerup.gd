extends Node
class_name Powerup

@onready var player: CharacterBody2D

func _ready() -> void:
	player = Game.get_player()
	player.connect("ground_pound", on_ground_pound)

func on_ground_pound():
	pass
