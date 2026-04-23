extends Powerup

func _ready() -> void:
	super()
	if player.weapon != null:
		player.weapon.queue_free()
	player.equip_weapon(load("res://world/objects/weapons/hand_gun/hand_gun.tres"), WeaponPickup.new())
