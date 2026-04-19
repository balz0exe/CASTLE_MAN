extends Node
class_name RoundHandler

var spawn_timer: float = 0
var spawn_time: float = 1
var _round: int = 0
var enem_round_count: int = 0
var enem_count: = 0
var current_round_id: int = 0

var round_in_progress: bool = false

var lava_floor: bool = false

var score: int = 0

var active_events: Array = []
var round_events = [
	{ name = "falling weapons", script = load("res://world/levels/round events/falling_weapons.gd"), weight = 4, min_round = 3 },
	{ name = "floor is lava", script = load("res://world/levels/round events/floor_is_lava/floor_is_lava.gd"), weight = 6, min_round = 5 },
	{ name = "falling barrels", script = load("res://world/levels/round events/falling_barrels.gd"), weight = 10, min_round = 2 },
	{ name = "falling exploding barrels", script = load("res://world/levels/round events/falling exploding barrels.gd"), weight = 4, min_round = 6 },
	{ name = "moon gravity", script = load("res://world/levels/round events/moon_gravity.gd"), weight = 5, min_round = 5 },
	{ name = "darkness", script = load("res://world/levels/round events/darkness.gd"), weight = 3, min_round = 2 }
]

var enemies = [
	{ name = "goblin", scene = load("res://enemies/scenes/goblin.tscn"), weight = 4, min_round = 5 },
	{ name = "skeleton", scene = load("res://enemies/scenes/skeleton.tscn"), weight = 8, min_round = 1 },
	{ name = "captain", scene = load("res://enemies/scenes/goblin_captain.tscn"), weight = 2, min_round = 8 },
	{ name = "slime", scene = load("res://enemies/scenes/slime.tscn"), weight = 6, min_round = 1 },
	{ name = "mushroom", scene = load("res://enemies/scenes/mushroom.tscn"), weight = 5, min_round = 2 }
]

func _physics_process(delta: float) -> void:
	if spawn_timer >= 0:
		spawn_timer -= 1 * delta

func _ready() -> void:
	new_round()

func new_round():
	if not is_instance_valid(self):
		return
	await Game.wait_for_seconds(5)
	_round += 1
	if _round != 1: score += 10
	current_round_id += 1
	enem_count = 0
	var round_id = current_round_id
	run_round_events(round_id)
	print("round " + str(_round) + " begins")
	enem_round_count = enemies_for_round(_round)
	round_in_progress = true
	for i in range(enem_round_count):
		spawn_timer = spawn_time
		spawn_enemy(_round)
		while spawn_timer > 0:
			await Game.wait_for_seconds(get_physics_process_delta_time())
	print("round " + str(_round) + " full")
	while enem_count > 0:
		await Game.wait_for_seconds(get_physics_process_delta_time())
	print("round " + str(_round) + " over")
	for event in active_events:
		if is_instance_valid(event):
			await event.clean_up()
			event.queue_free()
	active_events.clear()
	new_round()

func events_for_round(r: int) -> int:
	var value: int
	if r >= 3 and r < 6:
		value = randi() % 2
	elif r >= 6 and r < 11:
		value = randi() % 3
	elif r >= 11 and r < 13:
		value = randi() % 4
	elif r >= 13 and r < 20:
		value = randi() % 3 + 1
	elif r >= 20:
		value = randi() % 4 + 2
	else:
		value = 0
	
	return value

func run_round_events(round_id: int):
	var count = events_for_round(_round)
	var events = pick_events(_round, count)
	for e in events:
		print("event: " + e.name)
		if e.script:
			var instance = e.script.new()
			add_child(instance)
			active_events.append(instance)
			instance.start(round_id)

func pick_events(_round_num: int, count: int) -> Array:
	var available = round_events.filter(func(e):
		return e.min_round <= _round_num
	)
	var picked: Array = []
	for i in range(count):
		if available.is_empty():
			break
		var total_weight = 0
		for e in available:
			total_weight += e.weight
		var roll = randf() * total_weight
		for e in available:
			roll -= e.weight
			if roll <= 0:
				picked.append(e)
				available.erase(e)
				break
	return picked

func pick_enemy(_round_num: int) -> PackedScene:
	var available = enemies.filter(func(e):
		return e.min_round <= _round_num
	)
	var total_weight = 0
	for e in available:
		total_weight += e.weight
	var roll = randf() * total_weight
	for e in available:
		roll -= e.weight
		if roll <= 0:
			return e.scene
	return available.back().scene

func spawn_enemy(_round_num: int, fall: bool = false):
	var scene = pick_enemy(_round_num)
	if !fall:
		var dir = [1, -1].pick_random()
		var pos = Vector2(900 * dir, 100) if !lava_floor else Vector2(randi_range(-475, 475), -get_viewport().size.y)
		var enemy: Enemy = Game.spawn_object(scene, pos)
		var ai = enemy.ENEMY_AI
		var round_id = current_round_id
		ai.enemy = Game.get_player()
		enemy.died.connect(func(): on_enemy_died(round_id))
		enem_count += 1
		print("spawned enemy " + str(enem_count))

func on_enemy_died(round_id):
	score += 1
	if round_id != current_round_id:
		return
	enem_count -= 1
	print("enemy killed, enem_count = " + str(enem_count))

func enemies_for_round(r: int) -> int:
	var A = 3
	var B = 1
	var k = 1.1
	return int(A + B * pow(r, k))
