@tool
extends Node2D
class_name WeaponObject

@onready var sprite = $Sprite2D

var added: bool =false

var weapon: WeaponPickup
@export var res: WeaponResource:
	set(value):
		# Prevent unnecessary respawn if same resource assigned
		if res == value:
			return

		res = value
		if sprite == null: sprite = $Sprite2D
		sprite.texture = res.image

		# Remove old weapon if it exists
		if is_instance_valid(weapon):
			weapon.queue_free()
			weapon = null

		# Spawn new one if resource exists
		if res != null and !Engine.is_editor_hint():
			weapon = WeaponPickup.new()
			if !added:
				added = true
				call_deferred("add_weapon", weapon)

func _ready() -> void:
	if !Engine.is_editor_hint(): Game.spawn_object(res, global_position)
	if res != null:
		sprite.texture = res.image
	if Engine.is_editor_hint():
		sprite.visible = true
	else:
		sprite.visible = false

func add_weapon(w):
	get_parent().add_child(w)
	w.global_position = global_position
	w.res = res

func _exit_tree():
	if is_instance_valid(weapon):
		weapon.queue_free()
