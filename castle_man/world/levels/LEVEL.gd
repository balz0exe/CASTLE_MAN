class_name LEVEL
extends Node2D

@onready var player = $Knight
@onready var canvas = $CanvasModulate
@onready var camera = player.camera
@export var music = ""

func get_music_path():
	return music

func _ready():
	scale.y = 1
	if has_method("_start_cutscene_logic"):
		call_deferred("_start_cutscene_logic")
	Game.play_level_music()
