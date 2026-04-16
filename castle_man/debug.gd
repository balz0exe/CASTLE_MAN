extends Label

var debug_list: Array[String]
@onready var player = Game.get_player()
var state
var state_v
var weapon
var velocity
var direction
var flip_h
var has_weapon
var dead
var invincible

var is_ready = false

func _ready() -> void:
	Game.wait_for_seconds(3)
	is_ready = true

func _physics_process(_delta: float) -> void:
	if is_ready:
		state_v = "version: " + str(player.state_version)
		dead = "dead: " + str(player.dead)
		direction = "direction: " + str(player.direction)
		flip_h = "flip_h: " + str(player.flip_h)
		state = "state: " + player.state_machine.current_state.get_state_name()
		has_weapon = "has_weapon: " + str(player.has_weapon)
		if player.weapon == null:
			weapon = "weapon: none"
		elif player.weapon!= null:
			weapon = "weapon: " + str(player.weapon.weapon_name)
		velocity = "velocity: " + str(player.velocity)
		invincible = "invincible: " + str(player.invincible)
	
	debug_list = [
		dead,
		state,
		state_v,
		weapon,
		velocity,
		direction,
		flip_h,
		has_weapon,
		invincible
	]
	
	text = str(debug_list)
