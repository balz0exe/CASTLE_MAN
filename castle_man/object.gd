class_name WorldObject
extends RigidBody2D

@onready var anim = $AnimatedSprite2D

@export var max_health: int = 1
var health = max_health
@export var breakable: bool = true
@export var ground: bool = true
@export var drop: PackedScene

func _ready() -> void:
	if ground:
		add_to_group("enviroment")
		collision_layer = 1
		collision_mask = 1
	else:
		collision_layer = 0
		collision_mask = 1
	
func take_damage(damage, from: Node2D, knockback: float = 10):
	var knock_back_direction = -sign(from.global_position - global_position)
	var knockback_force: Vector2 = 15 * knockback * knock_back_direction
	apply_impulse(knockback_force)
	if breakable:
		health -= damage
		if health < 0:
			_break()


func _break():
	if anim.sprite_frames.has_animation("break"):
		anim.play("break")
		await anim.animation_finished
	queue_free()

func _physics_process(delta: float) -> void:
	pass
