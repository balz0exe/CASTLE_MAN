extends DirectionalLight2D

func _init() -> void:
	energy = 0
	
func _ready() -> void:
	for i in range(5):
		energy += 0.1
		await Game.wait_for_seconds(0.3)
