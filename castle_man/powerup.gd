extends Label

var debug_list: Array[String]
var player: Node
var powerup

func _physics_process(_delta: float) -> void:
	if Game.get_player():
		player = Game.get_player()
		if player.powerup!= null:
			powerup = "powerup: " + str(player.powerup.name)
		else:
			powerup = "powerup: <empty>"
		
		debug_list = [
			powerup,
		]
		
		text = str(debug_list)
