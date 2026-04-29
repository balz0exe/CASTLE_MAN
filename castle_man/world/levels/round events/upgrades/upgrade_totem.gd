extends Area2D
class_name UpgradeTotem

@onready var fire: CPUParticles2D = $ball2

var upgrade: Powerup = null
var stackable: bool = false

var cost: int

func reset():
	upgrade = null
	stackable = false
