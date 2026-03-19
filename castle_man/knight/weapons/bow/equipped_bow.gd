extends WeaponItem

var loaded : bool = false
var playing : bool = false

func _physics_process(_delta: float) -> void:
	if owner_player.state_machine.current_state.get_state_name() == "ThrowState":
		play_drawback()
	else:
		sprite.frame = 0
		playing = false

func play_drawback() -> void:
	if !playing:
		playing = true
		sprite.frame = 0
		await Game.wait_for_seconds(0.2)
		sprite.frame = 1
		await Game.wait_for_seconds(0.2)
		sprite.frame = 2
		loaded = true
