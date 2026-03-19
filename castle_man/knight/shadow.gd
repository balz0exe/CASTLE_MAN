extends Node

var player : CharacterBody2D

var floor_height : float
@onready var sprite = $ShadowSprite
@onready var cast = $ShadowCast
@onready var original_position = sprite.position

func _ready() -> void:
	player = get_parent()
	

func _physics_process(delta: float) -> void:
	find_floor(delta)
	sprite.position.y = floor_height - (original_position.y)
	sprite.position.x = player.animation.position.x
	sprite.flip_h = player.flip_h

func find_floor(_delta) -> void:
	cast.target_position.y = get_viewport().size.y
	if cast.is_colliding() and cast.get_collider().is_in_group("enviroment"):
		floor_height = original_position.y + (cast.get_collision_point().y - player.global_position.y)
		
