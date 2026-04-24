extends Node

@onready var parent: RigidBody2D = get_parent()

func on_thrown(_delta):
	parent.angular_velocity = 50
