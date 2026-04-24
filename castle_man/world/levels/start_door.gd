extends Sprite2D

@onready var area = $Area2D
@onready var label = $Label
@onready var player = Game.get_player()

var started = false

func _physics_process(delta: float) -> void:
	if area.get_overlapping_bodies().has(player):
		player.interaction_active = true
		label.visible = true
		if Input.is_action_just_pressed("drop_item") and !started:
			start()
	else:
		player.interaction_active = false
		label.visible = false

func start():
	started = true
	for i in range(3):
		frame += 1
		await Game.wait_for_seconds(0.3)
	Game.go_to_scene(load("res://world/levels/main_level.tscn"))
