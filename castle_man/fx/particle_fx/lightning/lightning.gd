extends Node2D

@onready var a = $CPUParticles2D2
@onready var b = $CPUParticles2D4
@onready var c = $CPUParticles2D5
@onready var d = $CPUParticles2D

@onready var hit_box = $HitBox

var time = 20

func _ready() -> void:
	Game.play_sfx(load("res://fx/audio_fx/lightning_strike.wav"), Game.sfx_volume, self)
	await Game.wait_for_seconds(1.5)
	Game.fade_out_sprite(a)
	Game.fade_out_sprite(b)
	Game.fade_out_sprite(c)
	await Game.wait_for_seconds(time)
	await Game.fade_out_sprite(d)
	queue_free()
