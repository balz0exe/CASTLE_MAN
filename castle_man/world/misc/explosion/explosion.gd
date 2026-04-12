extends Area2D

@onready var coll = $CollisionShape2D
@onready var fire = $FireParticle
@onready var circle = $CircleParticle

var _damage
var _knockback

func _ready() -> void:
	connect("body_entered", on_body_entered)

func explode(radius: int = 30, damage: int = 10, knockback: float = 50):
	coll.shape.radius = radius
	fire.emission_sphere_radius = radius + 10
	fire.amount = radius *2.1
	circle.emitting = true
	fire.emitting = true
	
	_damage = damage
	_knockback = knockback
	
	Game.hit_pause(0.1, 0.1, true)
	
	while fire.emitting:
		await get_tree().process_frame
	
	queue_free()

var hit_bodies : Array[Node2D] = []

func on_body_entered(body):
	if body.has_method("take_damage") and !hit_bodies.has(body):
		hit_bodies.append(body)
		body.call_deferred("take_damage", _damage, self, _knockback)
