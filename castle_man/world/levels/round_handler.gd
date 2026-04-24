# round_handler.gd
# Manages the game loop — spawning enemies, running events, and offering upgrades.
# Attached as a child of the level scene.
extends Node
class_name RoundHandler

# =========================================
# ROUND VARIABLES
# =========================================

var spawn_timer: float = 0
var spawn_time: float = 1
var _round: int = 2
var enem_round_count: int = 0
var enem_count: int = 0
var current_round_id: int = 0
var round_in_progress: bool = false
var score: int = 0

# =========================================
# EVENT & UPGRADE TRACKING
# =========================================

var lava_floor: bool = false
var upgrade_event: bool = false
var active_events: Array = []
var active_event_names: Array[String] = []
var active_nonstackable_upgrades: Array[String] = []  # upgrades that can only be taken once

# =========================================
# ROUND EVENT DEFINITIONS
# Weighted random selection — higher weight = more likely
# min_round controls when an event can first appear
# =========================================

var round_events = [
	#{ name = "falling weapons", script = load("res://world/levels/round events/falling_knives.gd"), weight = 4, min_round = 3 },
	#{ name = "floor is lava", script = load("res://world/levels/round events/floor_is_lava/floor_is_lava.gd"), weight = 6, min_round = 5 },
	#{ name = "falling barrels", script = load("res://world/levels/round events/falling_barrels.gd"), weight = 12, min_round = 2 },
	#{ name = "falling exploding barrels", script = load("res://world/levels/round events/falling exploding barrels.gd"), weight = 4, min_round = 6 },
	#{ name = "moon gravity", script = load("res://world/levels/round events/moon_gravity.gd"), weight = 5, min_round = 5 },
	{ name = "darkness", script = load("res://world/levels/round events/darkness/darkness.gd"), weight = 3, min_round = 2 },
]

# =========================================
# ENEMY DEFINITIONS
# Same weighted system as events
# =========================================

var enemies = [
	{ name = "goblin", scene = load("res://enemies/scenes/goblin.tscn"), weight = 4, min_round = 5 },
	{ name = "skeleton", scene = load("res://enemies/scenes/skeleton.tscn"), weight = 8, min_round = 1 },
	{ name = "captain", scene = load("res://enemies/scenes/goblin_captain.tscn"), weight = 2, min_round = 8 },
	{ name = "slime", scene = load("res://enemies/scenes/slime.tscn"), weight = 6, min_round = 1 },
	{ name = "mushroom", scene = load("res://enemies/scenes/mushroom.tscn"), weight = 5, min_round = 2 },
]

# =========================================
# DROPS
# Same weighted system as events
# =========================================

var drops = [
	[load("res://knight/powerups/exploding boots/exploding_boots.tres"), 5],
	[load("res://knight/powerups/health potion/health_potion.tres"), 20],
	[load("res://knight/powerups/stamina potion/stamina_potion.tres"), 20],
	[load("res://enemies/scenes/slime.tscn"), 10],
	[load("res://world/objects/weapons/axe/hand_axe.tres"), 15],
	[load("res://world/objects/weapons/sword/sword.tres"), 15],
	[load("res://world/objects/weapons/spear/spear.tres"), 10],
	[load("res://world/objects/weapons/bow/bow.tres"), 8],
	[load("res://world/objects/weapons/great_sword/great_sword.tres"), 5],
	[load("res://world/objects/weapons/mace/mace.tres"), 8],
	[load("res://knight/powerups/mushroom friend/mushroom_friend.tres"), 5],
]

# =========================================
# PHYSICS PROCESS
# =========================================

func _physics_process(delta: float) -> void:
	# Tick spawn timer down each frame
	if spawn_timer >= 0:
		spawn_timer -= delta

# =========================================
# READY
# =========================================

func _ready() -> void:
	if !active_events.is_empty():
		for e in active_events:
			e.queue_free()
	new_round()
	call_deferred("spawn_start_objects")

func spawn_start_objects():
	var objects = [
		{ name = "barrel", scene = load("res://world/objects/barrels/barrel.tscn"), weight = 10},
		{ name = "exploding_barrel", scene = load("res://world/objects/barrels/exploding_barrel.tscn"), weight = 2},
	]
	for i in range(25):
		var d = pick_start_object(objects)
		var name = d.name
		var object = d.scene
		object = object.instantiate()
		Game.get_level().add_child(object)
		print(object.name)
		if name == "barrel":
			var ran = [1, -1].pick_random()
			if ran == 1:
				object.drop = pick_weighted_drop()
		object.global_position = Vector2(randi_range(-750, 750), 100)

func pick_weighted_drop():
	var total_weight: float = 0.0
	for drop in drops:
		total_weight += drop[1]
	var roll = randf_range(0.0, total_weight)
	var cumulative: float = 0.0
	for drop in drops:
		cumulative += drop[1]
		if roll <= cumulative:
			return drop[0]
	return drops[-1][0]

func pick_start_object(objects):
	# Weighted random pick from eligible enemies
	var available = objects
	var total_weight = 0
	for e in available:
		total_weight += e.weight
	var roll = randf() * total_weight
	for e in available:
		roll -= e.weight
		if roll <= 0:
			return e
	return available.back()

# =========================================
# MAIN GAME LOOP
# Linear flow: wait → spawn → wait for clear → clean up events → upgrade → repeat
# =========================================

func new_round():
	if not is_instance_valid(self):
		return

	await Game.wait_for_seconds(5)

	_round += 1
	if _round != 1:
		score += 10
	current_round_id += 1
	enem_count = 0

	var round_id = current_round_id
	run_round_events(round_id)

	print("round " + str(_round) + " begins")
	enem_round_count = enemies_for_round(_round)
	round_in_progress = true

	# Spawn all enemies for this round spaced by spawn_time
	for i in range(enem_round_count):
		spawn_timer = spawn_time
		spawn_enemy(_round)
		while spawn_timer > 0:
			await Game.wait_for_seconds(get_physics_process_delta_time())

	print("round " + str(_round) + " full")

	# Wait for all enemies to die before ending the round
	while enem_count > 0:
		await Game.wait_for_seconds(get_physics_process_delta_time())

	print("round " + str(_round) + " over")

	# Clean up all active round events before showing upgrades
	for event in active_events:
		if is_instance_valid(event):
			await event.clean_up()
			event.queue_free()
	active_events.clear()
	active_event_names.clear()

	# Show upgrade selection and wait for player to choose before continuing
	await _upgrade_event()

	new_round()

# =========================================
# UPGRADE EVENT
# Spawns the upgrade platform, waits for player to pick, then cleans up
# =========================================

func _upgrade_event():
	var instance = load("res://world/levels/round events/upgrades/upgrade_event.gd").new()
	add_child(instance)
	current_round_id += 1
	instance.start(current_round_id)
	await instance.upgrade_chosen
	await instance.clean_up()

# =========================================
# ROUND EVENT SYSTEM
# =========================================

func events_for_round(r: int) -> int:
	# Returns a random number of events scaled to round number
	if r >= 3 and r < 6:
		return randi() % 2
	elif r >= 6 and r < 11:
		return randi() % 3 + 1
	elif r >= 11 and r < 13:
		return randi() % 4 + 1
	elif r >= 13 and r < 20:
		return randi() % 4 + 1
	elif r >= 20:
		return randi() % 5 + 2
	return 0

func run_round_events(round_id: int) -> void:
	var count = events_for_round(_round)
	var events = pick_events(_round, count)
	for e in events:
		print("event: " + e.name)
		active_event_names.append(e.name)
		if e.script:
			var instance = e.script.new()
			add_child(instance)
			active_events.append(instance)
			instance.start(round_id)

func pick_events(_round_num: int, count: int) -> Array:
	# Filter to eligible events then weighted pick without replacement
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

# =========================================
# ENEMY SYSTEM
# =========================================

func pick_enemy(_round_num: int) -> PackedScene:
	# Weighted random pick from eligible enemies
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

func spawn_enemy(_round_num: int, fall: bool = false) -> void:
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

func on_enemy_died(round_id: int) -> void:
	score += 1
	if round_id != current_round_id:
		return
	enem_count -= 1
	print("enemy killed, enem_count = " + str(enem_count))

# =========================================
# ROUND SCALING
# Formula: A + B * r^k
# A = base count, B = multiplier, k = curve
# =========================================

func enemies_for_round(r: int) -> int:
	var A = 1
	var B = 1.5
	var k = 1.2
	return int(A + B * pow(r, k))
