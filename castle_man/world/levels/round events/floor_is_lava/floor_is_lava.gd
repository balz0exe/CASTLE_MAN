extends RoundEvent
class_name FloorIsLava

var final_lava_height: float = 165
var lava_height: float = 500
var damage_per_hit: float = 10
var map

func start(value):
	super(value)
	manager.lava_floor = true
	map = load("res://world/levels/round events/floor_is_lava/lava_tile_map.tscn")
	map = map.instantiate()
	map.global_position = Vector2(0, lava_height + 30)
	manager.get_parent().add_child(map)
	raise_lava()

func raise_lava():
	var original_height = lava_height
	for i in range((original_height - final_lava_height) / 5):
		lava_height -= 5
		await Game.wait_for_seconds(0.05)
		Game.camera_shake(0.1, 1)

func lower_lava():
	var original_height = lava_height
	for i in range((original_height - final_lava_height) / 5):
		lava_height += 5
		await Game.wait_for_seconds(0.05)
		Game.camera_shake(0.1, 1)

func clean_up():
	manager.lava_floor = false
	if map != null:
		map.queue_free()
		map = null

func _physics_process(delta: float) -> void:
	super(delta)
	if map != null:
		map.global_position = Vector2(0, lava_height + 30)
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
	if player.is_class("CharacterBody2D"): player.take_damage(damage_per_hit, null)
	elif player.is_in_group("weapons"): player.queue_free()
	elif player.is_in_group("objects"): player.health = 0
	if player.is_class("CharacterBody2D"): player.velocity.y = min(player.velocity.y, -200)
