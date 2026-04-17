extends Area2D

@onready var coll = $CollisionShape2D

func _ready() -> void:
	connect("body_entered", on_body_entered)
	get_parent().connect("ground_pound", on_ground_pound)

func on_ground_pound():
	coll.disabled = false
	async_deactivate()

func async_deactivate():
	await Game.wait_for_seconds(0.05)
	coll.disabled = true
	hit_bodies.clear()

var hit_bodies : Array[Node2D] = []

func on_body_entered(body):
	if body.has_method("take_damage") and !hit_bodies.has(body) and body != get_parent():
		hit_bodies.append(body)
		body.take_damage(0, get_parent(), get_parent().groundpound_knockback)
