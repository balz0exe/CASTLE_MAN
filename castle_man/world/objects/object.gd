class_name WorldObject
extends RigidBody2D

@onready var anim = $AnimatedSprite2D
@onready var push_area = $PushArea

@export var max_health: float = 1
var health : float
@export var breakable: bool = false
var broken : bool = false
@export var ground: bool = false
@export var pushable: bool = false
@export var collide_with_objects: bool = true
@export var pixel_break: bool = true
@export var drop: Resource

signal _broken

func _ready() -> void:
	connect("_broken", on_broken)
	if collide_with_objects:
		set_collision_mask_value(6, true)
		set_collision_layer_value(6, true)
		
	z_index = 0
	push_area.connect("body_entered", _on_push_area_body_entered)
	health = max_health
	if ground:
		add_to_group("enviroment")
		set_collision_layer_value(1, true)
	else:
		set_collision_layer_value(1, false)
		
func take_damage(damage, from: Node2D, knockback: float = 10):
	if !broken:
		var knock_back_direction = -sign(from.global_position - global_position)
		var knockback_force: Vector2 = 15 * knockback * knock_back_direction
		apply_impulse(knockback_force)
		if breakable:
			health -= damage
			if health < 0:
				_break()

func _on_push_area_body_entered(from) -> void:
	if !broken:
		if !pushable:
			return
		var knock_back_direction = -sign(from.global_position - global_position)
		var knockback_force: Vector2 = 15 * 10 * knock_back_direction
		apply_impulse(knockback_force)

func _drop_item():
	if drop:
		await get_tree().process_frame
		if drop != null:
			var _drop = drop.instantiate()
			_drop.global_position = global_position
			get_parent().add_child(_drop)

func _break():
	if drop != null:
		_drop_item()
	broken = true
	_broken.emit()
	set_collision_layer_value(6, false)
	if pixel_break: Game.spawn_particle_oneshot("res://fx/particle_fx/object_break_particles.tscn", self)
	await Game.fade_out_sprite(anim, 0.05)
	if !pixel_break: queue_free()

func _physics_process(_delta: float) -> void:
	pass

func on_broken() -> void:
	pass
