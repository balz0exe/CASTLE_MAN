extends Node
class_name RoundEvent

@onready var manager: RoundHandler = get_parent()
var round_id

func _physics_process(_delta: float) -> void:
	if round_id != manager.current_round_id:
		queue_free()
		return

func start(value):
	round_id = value

func clean_up():
	pass
