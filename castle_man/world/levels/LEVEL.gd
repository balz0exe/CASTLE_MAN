class_name LEVEL
extends Node2D

@onready var player = Game.get_player()
@onready var canvas = $CanvasModulate
@onready var camera = player.camera
@export var music = ""
@export var boundaries: Dictionary = {
	"x_boundaries" = Vector2(),
	"y_boundaries" = Vector2()
}

func get_music_path():
	return music

func _ready():
	canvas.color = Game.COLOR
	scale.y = 1
	if has_method("_start_cutscene_logic"):
		call_deferred("_start_cutscene_logic")
	Game.play_level_music()
	if boundaries["x_boundaries"] != Vector2.ZERO:
		player.camera.limit_left = boundaries["x_boundaries"].x
		var l_wb = StaticBody2D.new()
		var l_wb_coll = CollisionShape2D.new()
		add_child(l_wb)
		l_wb.add_child(l_wb_coll)
		l_wb_coll.shape = WorldBoundaryShape2D.new()
		l_wb.global_position.x = boundaries["x_boundaries"].x - 100
		l_wb_coll.shape.normal = Vector2(1, 0)
		
		player.camera.limit_right = boundaries["x_boundaries"].y
		var r_wb = StaticBody2D.new()
		var r_wb_coll = CollisionShape2D.new()
		add_child(r_wb)
		r_wb.add_child(r_wb_coll)
		r_wb_coll.shape = WorldBoundaryShape2D.new()
		r_wb.global_position.x = boundaries["x_boundaries"].y + 100
		r_wb_coll.shape.normal = Vector2(-1, 0)
		
	if boundaries["y_boundaries"] != Vector2.ZERO:
		player.camera.limit_top = boundaries["y_boundaries"].x
		player.camera.limit_bottom = boundaries["y_boundaries"].y
