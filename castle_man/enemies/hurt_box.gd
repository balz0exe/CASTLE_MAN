extends Area2D

@onready var coll = $CollisionShape2D
var player

func _ready() -> void:
	player = get_parent()

func _physics_process(_delta: float) -> void:
	if player != null:
		if player.is_in_group("enemies") and player.basic_attack:
			coll.position.y = 0
			coll.position.x = player.direction * coll.position.x
			return
		if player.animation.animation == "attack up" or player.animation.animation == "attack down":
			if player.animation.animation == "attack up":
				coll.position.x = 0
				coll.position.y = -30 - (player.weapon_hurt_box_reach_offset)
			if player.animation.animation == "attack down":
				coll.position.x = 0
				coll.position.y = 20
		else:
			coll.position.y = 0
			if player.direction == 1:
				coll.position.x = 30 + (player.weapon_hurt_box_reach_offset)
			if player.direction == -1:
				coll.position.x = -30 - (player.weapon_hurt_box_reach_offset)
