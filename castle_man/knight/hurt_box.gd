class_name HurtBox
extends Area2D

@onready var coll = $CollisionShape2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 16
	connect("area_entered", on_area_entered)
	
func on_area_entered(hit_box: HitBox):
	if hit_box == null:
		return
	if owner.has_method("take_damage"):
		if hit_box.owner.weapon != null:
			owner.take_damage(hit_box.owner.weapon.damage, hit_box.owner, hit_box.owner.weapon.knockback)
		else:
			owner.take_damage(hit_box.owner.damage_factor, hit_box.owner)
