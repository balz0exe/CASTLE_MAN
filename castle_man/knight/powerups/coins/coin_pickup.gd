extends Node

@onready var ground_cast = RayCast2D.new()

var up_force = 10

func _ready() -> void:
	get_parent().sprite.scale = Vector2.ONE*0.3
	get_parent().lock_rotation = true
	ground_cast.target_position = Vector2(0, 5)
	get_parent().add_child(ground_cast)
	await Game.wait_for_seconds(10)
	await Game.fade_out_sprite(get_parent(), 5)
	get_parent().queue_free()

func _physics_process(delta: float) -> void:
	if ground_cast.is_colliding() and ground_cast.get_collider().is_in_group("enviroment"):
		get_parent().apply_impulse((Vector2.UP*randf_range(5.0, 7.5)*up_force)*Engine.time_scale)
		if up_force > 0:
			up_force -= delta * 50
			Game.play_sfx(load("res://fx/audio_fx/coin_bounce.wav"), Game.sfx_volume - 24, get_parent())
	
