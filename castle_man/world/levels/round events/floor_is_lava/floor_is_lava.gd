extends RoundEvent

var final_lava_height: float = 50
var lava_height: float = 500
var lava_up: bool = false
var damage_per_hit: float = 10
var original_height
var map

func start(value):
	super(value)
	manager.lava_floor = true
	map = load("res://world/levels/round events/floor_is_lava/lava_tile_map.tscn")
	map = map.instantiate()
	map.global_position = Vector2(0, lava_height + 30)
	manager.get_parent().add_child(map)
	var tween = create_tween()
	tween.tween_property(get_tree().get_first_node_in_group("LevelScene").canvas, "color", Color.RED, 3)
	raise_lava()

func raise_lava():
	lava_up = true
	original_height = lava_height
	for i in range((original_height - final_lava_height) / 5):
		lava_height -= 5
		await Game.wait_for_seconds(0.05)
		Game.camera_shake(0.1, 1)

func lower_lava():
	lava_up = false
	Game.get_player().camera._set_offset(Vector2(0, 0))
	for i in range((original_height - final_lava_height) / 5):
		lava_height += 5
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
	manager.lava_floor = false
	await Game.wait_for_seconds(0.05)

func clean_up():
	await lower_lava()
	print("free map")
	var _tween = create_tween()
	_tween.tween_property(get_tree().get_first_node_in_group("LevelScene").canvas, "color", Game.COLOR, 3)
	while get_tree().get_first_node_in_group("LevelScene").canvas.color != Game.COLOR:
		await get_tree().process_frame
	queue_free()

func _physics_process(delta: float) -> void:
	super(delta)
	if lava_up:
		Game.get_player().camera.limit_bottom = lerp(Game.get_player().camera.limit_bottom, 220, delta)
	else:
		Game.get_player().camera.limit_bottom = lerp(Game.get_player().camera.limit_bottom, 570, delta)
	if map != null:
		var prev_y = map.global_position.y
		map.global_position = Vector2(0, lava_height + 30)
		# Move anything sitting on top of the map with it
		var move_delta = map.global_position.y - prev_y
		if map.has_node("Area2D"):
			for body in map.get_node("Area2D").get_overlapping_bodies():
				body.global_position.y += move_delta
	if !manager.lava_floor:
		return
	var characters = Game.get_characters()
	var objects = Game.get_objects()
	for character in characters:
		if character.global_position.y >= lava_height:
			apply_lava(character)
	for object in objects:
		if object.global_position.y >= lava_height:
			apply_lava(object)

func apply_lava(player):
	if player.is_class("CharacterBody2D"): player.take_damage(1, null, 0, true)
	if player.is_in_group("weapons"): player.queue_free()
	elif player.is_in_group("objects"): 
		if player.get("powerup") == true:
			player.queue_free()
		else:
			player.health = 0
	if player.is_class("CharacterBody2D"): player.velocity.y = min(player.velocity.y, -200)
