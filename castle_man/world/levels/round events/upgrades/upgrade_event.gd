extends RoundEvent

var final_height: float = 165
var height: float = 500
var up: bool = false
var damage_per_hit: float = 10
var original_height
var map

func start(value):
	super(value)
	manager.upgrade_event = true
	map = load("res://world/levels/round events/upgrades/upgrade_tilemap.tscn")
	map = map.instantiate()
	map.global_position = Vector2(0, height + 30)
	manager.get_parent().add_child(map)
	raise()

func raise():
	up = true
	original_height = height
	for i in range((original_height - final_height) / 5):
		height -= 5
		await Game.wait_for_seconds(0.05)
		Game.camera_shake(0.1, 1)

func lower():
	up = false
	Game.get_player().camera._set_offset(Vector2(0, 0))
	for i in range((original_height - final_height) / 5):
		height += 5
		await Game.wait_for_seconds(0.05)
		Game.camera_shake(0.1, 1)
	if map != null:
		map.queue_free()
		map = null
		var objects = Game.get_objects()
		var weapons = []
		for o in objects:
			if o.is_in_group("weapons"):
				weapons.append(o)
		for w in weapons:
			w.apply_impulse(Vector2(0, -10))
	manager.upgrade_event = false
	await Game.wait_for_seconds(0.05)

func clean_up():
	await lower()
	print("free map")
	queue_free()

func _physics_process(delta: float) -> void:
	super(delta)
	if map != null:
		var prev_y = map.global_position.y
		map.global_position = Vector2(0, height + 30)
		# Move anything sitting on top of the map with it
		var move_delta = map.global_position.y - prev_y
		if map.has_node("Area2D"):
			for body in map.get_node("Area2D").get_overlapping_bodies():
				body.global_position.y += move_delta
	if !manager.upgrade_event:
		return
