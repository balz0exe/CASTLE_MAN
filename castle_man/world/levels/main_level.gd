extends LEVEL

func _ready():
	super()
	await Game.wait_for_seconds(0.1)
	player.equip_weapon(load("res://world/objects/weapons/sword/sword.tres"), WeaponPickup.new())
