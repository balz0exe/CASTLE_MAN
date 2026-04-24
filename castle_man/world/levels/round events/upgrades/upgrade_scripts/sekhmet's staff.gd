extends Powerup

func _ready() -> void:
	super()
	
	var world = Game.get_level()
	var pickup = WeaponPickup.new()
	pickup.res = load("res://world/objects/weapons/wand/wand.tres")
	if player.weapon == null:
		player.equip_weapon(pickup.res, WeaponPickup.new())
	else:
		Game.spawn_object(pickup.res, player.global_position+Vector2(25, -25))
