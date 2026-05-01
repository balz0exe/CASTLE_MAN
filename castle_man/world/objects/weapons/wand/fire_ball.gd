extends Node

var hit = false
var ball

var radius = 40
var damage = 40

func _ready() -> void:
	ball = load("res://fx/particle_fx/fire_ball.tscn")
	ball = ball.instantiate()
	get_parent().add_child(ball)
	ball.scale = Vector2.ONE * 5

func on_hit(target):
	if !hit:
		hit = true
		get_parent().sleeping = true
		await get_tree().process_frame
		get_parent().queue_free()
		Game.spawn_explosion(target, radius, damage, 5, true)
