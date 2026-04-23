class_name HitBox
extends Area2D

@onready var coll = $CollisionShape2D if has_node("CollisionShape2D") else CollisionShape2D.new()
@onready var original_coll_position: Vector2
@onready var original_coll_shape: Shape2D
var player: Node2D

@export var dps_on: bool = false
@export var dps: float = 5.0
@export var damage_player: bool = true

func _ready() -> void:
	collision_layer = 16
	collision_mask = 16
	player = get_parent()
	while coll == null:
		await get_tree().process_frame
	original_coll_shape = coll.shape
	original_coll_position = coll.position
	connect("area_entered", _on_area_entered)

func _physics_process(_delta: float) -> void:
	if coll == null:
		return
	if player != null:
		if player.is_class("RigidBody2D"):
			if player.sprite.flip_h:
				coll.position = original_coll_position * -1
			else:
				coll.position = original_coll_position
		elif player.is_class("CharacterBody2D"):
			if player.is_in_group("enemies") and player.basic_attack:
				coll.shape = original_coll_shape
				coll.position.y = original_coll_position.y
				coll.position.x = player.direction * original_coll_position.x
				return
			if player.animation.animation == "attack up" or player.animation.animation == "attack down":
				if player.animation.animation == "attack up":
					coll.position.x = 0
					coll.position.y = -30 - (player.weapon_hit_box_reach_offset.x)
				if player.animation.animation == "attack down":
					coll.position.x = 0
					coll.position.y = 20
			else:
				coll.position.y = player.weapon_hit_box_reach_offset.y
				if player.direction == 1:
					coll.position.x = 30 + (player.weapon_hit_box_reach_offset.x)
				if player.direction == -1:
					coll.position.x = -30 - (player.weapon_hit_box_reach_offset.x)
					

func _on_area_entered(hurt_box: Area2D):
	if hurt_box == null:
		return
	pass
