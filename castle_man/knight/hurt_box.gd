class_name HurtBox
extends Area2D

@onready var coll = $CollisionShape2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 16
	connect("area_entered", on_area_entered)
	
func on_area_entered(hit_box: HitBox):
	if hit_box == null or (owner.is_in_group("enemies") and hit_box.owner.is_in_group("enemies")):
		return
	if owner.has_method("take_damage"):
		if hit_box.owner.weapon != null:
			if hit_box.owner.is_in_group("player"): owner.take_damage(hit_box.owner.weapon.damage, hit_box.owner, hit_box.owner.weapon.knockback)
			elif hit_box.owner.is_in_group("enemies"): owner.take_damage(hit_box.owner.weapon.damage * hit_box.owner.damage_factor, hit_box.owner, hit_box.owner.weapon.knockback)
		else:
			owner.take_damage(hit_box.owner.basic_damage, hit_box.owner)
		if hit_box.owner.is_in_group("player") or owner.is_in_group("player"):
			Game.hit_pause(0.05, 0.3)
