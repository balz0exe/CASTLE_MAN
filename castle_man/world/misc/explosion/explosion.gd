extends Area2D

@onready var coll = $CollisionShape2D
@onready var fire = $FireParticle
@onready var circle = $CircleParticle

var _damage
var _knockback
var from
var damage_from = false

func _ready() -> void:
	connect("body_entered", on_body_entered)

func explode(radius: int = 30, damage: int = 10, knockback: float = 50):
	coll.shape.radius = radius
	fire.emission_sphere_radius = radius + 2
	fire.amount = radius *2.1
	circle.emitting = true
	fire.emitting = true
	
	_damage = damage
	_knockback = knockback
	
	Game.hit_pause(0.1, 0.1, true)
	
	async_deactivate()
	
	while fire.emitting and get_tree() != null:
		await get_tree().process_frame
	
	queue_free()

func async_deactivate():
	await Game.wait_for_seconds(0.1)
	coll.disabled = true

var hit_bodies : Array[Node2D] = []

func on_body_entered(body):
	if body != from or damage_from == true:
		if body.has_method("take_damage") and !hit_bodies.has(body):
			hit_bodies.append(body)
			body.call_deferred("take_damage", _damage, self, _knockback)
