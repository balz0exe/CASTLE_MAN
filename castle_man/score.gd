extends Label

var debug_list: Array[String]
var player: Node
var score
var round_
var is_ready = false

func _ready() -> void:
	Game.wait_for_seconds(3)
	is_ready = true

func _physics_process(_delta: float) -> void:
	if Game.get_game_handler():
		player = Game.get_game_handler()
		if is_ready:
			score = "score: " + str(player.score)
			round_ = "round: " + str(player._round)
		
		debug_list = [
			score,
			round_,
		]
		
		text = str(debug_list)
