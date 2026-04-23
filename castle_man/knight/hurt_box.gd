class_name HurtBox
extends Area2D

@onready var coll = $CollisionShape2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 16
	connect("area_entered", on_area_entered)
	
func on_area_entered(hit_box: HitBox):
	if (get_parent().is_in_group("player") and (get_parent().invincible or hit_box.damage_player == false)) or (get_parent().is_in_group("object") and hit_box.is_in_group("projectile")):
		return
	if ((get_parent().is_in_group("enemies") and get_parent().friendly) or get_parent().is_in_group("player")) and ((hit_box.get_parent().is_in_group("enemies") and hit_box.get_parent().friendly)):
		return
	if hit_box == null or (get_parent().is_in_group("enemies") and (hit_box.get_parent().is_in_group("enemies") and !hit_box.get_parent().friendly)) or (hit_box.get_parent().is_in_group("enemies") and hit_box.get_parent().dead):
		return
	if get_parent().has_method("take_damage"):
		if hit_box.get_parent().is_class("RigidBody2D"):
			if hit_box.get_parent().from != null:
				if get_parent() != hit_box.get_parent().from: get_parent().take_damage(hit_box.get_parent().throw_damage * hit_box.get_parent().from.damage_factor, hit_box.get_parent())
			else:
				if get_parent() != hit_box.get_parent().from: get_parent().take_damage(hit_box.get_parent().throw_damage, hit_box.get_parent())
			if hit_box.get_parent().is_in_group("player") or get_parent().is_in_group("player"):
				Game.hit_pause(0.05, 0.3)
			if hit_box.get_parent().has_signal("hit"):
				hit_box.get_parent().hit.emit(get_parent())
			return
		elif hit_box.get_parent().is_class("CharacterBody2D"):
			if hit_box.get_parent().weapon != null:
				if hit_box.get_parent().is_in_group("player"): get_parent().take_damage(hit_box.get_parent().weapon.damage * hit_box.get_parent().damage_factor, hit_box.get_parent(), hit_box.get_parent().weapon.knockback)
				elif hit_box.get_parent().is_in_group("enemies"): get_parent().take_damage(hit_box.get_parent().weapon.damage * hit_box.get_parent().damage_factor, hit_box.get_parent(), hit_box.get_parent().weapon.knockback)
			else:
				get_parent().take_damage(hit_box.get_parent().basic_damage, hit_box.get_parent())
		elif hit_box.dps_on == true:
			while get_overlapping_areas().has(hit_box):
				await Game.wait_for_seconds(0.1)
				if hit_box == null:
					return
				get_parent().take_damage(hit_box.dps, hit_box.get_parent(), 0)
		if hit_box.get_parent().is_in_group("player") or get_parent().is_in_group("player"):
			Game.hit_pause(0.05, 0.3)
		if hit_box.get_parent().has_signal("hit"):
			hit_box.get_parent().hit.emit(get_parent())
