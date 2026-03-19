extends Node2D

@export var moving : bool = false
@export var speed : int = 1

@onready var ray_cast : = $RayCast2D
@onready var platform : = $map

var original_position

func _ready() -> void:
	original_position = global_position
	move()
	
func move():
	moving = true
	while moving:
		while global_position != ray_cast.target_position:
			global_position.y = move_toward(global_position.y, ray_cast.target_position.y, 1)
			global_position.x = move_toward(global_position.x, ray_cast.target_position.x, 1)
			await get_tree().process_frame
		while global_position != original_position:
			global_position.y = move_toward(global_position.y, original_position.y, 1)
			global_position.x = move_toward(global_position.x, original_position.x, 1)
			await get_tree().process_frame
