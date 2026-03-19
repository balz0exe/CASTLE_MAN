extends Node2D

@onready var torch = $Torch
@export var visible_torch = true

func _process(_delta: float) -> void:
	torch.visible = visible_torch
