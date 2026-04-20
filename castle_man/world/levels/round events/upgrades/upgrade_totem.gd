extends Area2D
class_name UpgradeTotem

@onready var fire: CPUParticles2D = $ball2

var upgrade: Powerup = null
var stackable: bool = false

func reset():
	upgrade = null
	stackable = false
