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
		label.visible = false

func start():
	started = true
	for i in range(3):
		frame += 1
		await Game.wait_for_seconds(0.3)
	Game.go_to_scene(load("res://world/levels/test_level.tscn"))

func _ready() -> void:
	area.connect("body_entered", on_body_entered)

func on_body_entered(body):
	if body.is_in_group("player"):
		while area.get_overlapping_bodies().has(body):
			await get_tree().process_frame
		player.interaction_active = false
