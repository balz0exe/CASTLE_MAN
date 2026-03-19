extends RigidBody2D
class_name Projectile

@onready var sprite = $Sprite2D
@onready var coll = $CollisionShape2D
@onready var hurt_box_l = $Area2D_L
@onready var hurt_box_r = $Area2D_R
@onready var interaction = $InteractionArea

@export var throw_speed = 100
@export var throw_damage = 5

var from: CharacterBody2D
var thrown: bool = false

func _ready() -> void:
	call_deferred("connect_interaction")
	contact_monitor = true

func _physics_process(_delta: float) -> void:
	var velocity = get_linear_velocity()
	if abs(velocity) > Vector2(5, 5) and thrown:
		if velocity.x > 0:
			hurt_box_r.monitoring = true
			hurt_box_l.monitoring = false
		if velocity.x < 0:
			hurt_box_l.monitoring = true
			hurt_box_r.monitoring = false
	else:
		thrown = false
		hurt_box_r.monitoring = false
		hurt_box_l.monitoring = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enviroment"):
		if abs(get_linear_velocity()) < Vector2(10, 10) or sleeping:
			queue_free()

func connect_interaction() -> void:
	if interaction != null:
		interaction.connect("body_entered", Callable(self, "_on_body_entered"))
