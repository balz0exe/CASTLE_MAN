extends PointLight2D
class_name GlowLight

@onready var original_energy = energy
@onready var modulate_factor = 1.6

func _process(_delta: float) -> void:
	var parent = get_parent()
	if parent == null: return
	energy = parent.modulate.a * modulate_factor
