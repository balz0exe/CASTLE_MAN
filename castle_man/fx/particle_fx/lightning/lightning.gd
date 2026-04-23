extends Node2D

@onready var a = $CPUParticles2D2
@onready var b = $CPUParticles2D4
@onready var c = $CPUParticles2D5

func _ready() -> void:
	await Game.wait_for_seconds(1.5)
	Game.fade_out_sprite(a)
	Game.fade_out_sprite(b)
	Game.fade_out_sprite(c)
