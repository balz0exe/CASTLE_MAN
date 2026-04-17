extends Node
class_name RoundHandler

var spawn_timer: float = 0
var spawn_time: float = 1
var _round: int = 10
var enem_round_count: int = 0
var enem_count: = 0
var current_round_id: int = 0

var round_in_progress: bool = false

var lava_floor: bool = false

var active_events: Array = []
var round_events = [
	#{ name = "falling weapons", script = load("res://world/levels/round events/falling_weapons.gd"), weight = 10, min_round = 2 },
	{ name = "floor is lava", script = load("res://world/levels/round events/floor_is_lava/floor_is_lava.gd"), weight = 6, min_round = 5 },
	#{ name = "falling barrels", script = load("res://world/levels/round events/falling_barrels.gd"), weight = 8, min_round = 3 },
	#{ name = "falling exploding barrels", script = load("res://world/levels/round events/falling exploding barrels.gd"), weight = 4, min_round = 6 },
	#{ name = "moon gravity", script = load("res://world/levels/round events/moon_gravity.gd"), weight = 5, min_round = 3 }
]

var enemies = [
	#{ name = "goblin", scene = load("res://enemies/scenes/goblin.tscn"), weight = 6, min_round = 5 },
	#{ name = "skeleton", scene = load("res://enemies/scenes/skeleton.tscn"), weight = 8, min_round = 1 },
	#{ name = "captain", scene = load("res://enemies/scenes/goblin_captain.tscn"), weight = 4, min_round = 8 },
	{ name = "slime", scene = load("res://enemies/scenes/slime.tscn"), weight = 6, min_round = 1 },
	{ name = "mushroom", scene = load("res://enemies/scenes/mushroom.tscn"), weight = 5, min_round = 2 }
]

func _physics_process(delta: float) -> void:
	if spawn_timer >= 0:
		spawn_timer -= 1*delta

func _ready() -> void:
	new_round()

func new_round():
	await Game.wait_for_seconds(5)
	_round += 1
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
		while spawn_timer >0:
			await get_tree().process_frame
	print("round " + str(_round) + " full")
	while enem_count > 0:
		await get_tree().process_frame
	print("round " + str(_round) + " over")
	for event in active_events:
		if is_instance_valid(event):
			await event.clean_up()
			event.queue_free()
	active_events.clear()
	new_round()

func events_for_round(r: int) -> int:
	if r >= 2 and r < 5:
		return 1
	elif r >= 5 and r < 10:
		return 2
	elif r >= 10:
		return 3
	else:
		return 0

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

		# weighted pick
		var total_weight = 0
		for e in available:
			total_weight += e.weight

		var roll = randf() * total_weight

		for e in available:
			roll -= e.weight
			if roll <= 0:
				picked.append(e)
				available.erase(e) # 🔥 prevents duplicates
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
	if round_id != current_round_id:
		return

	enem_count -= 1
	print("enemy killed, enem_count = " + str(enem_count))

func enemies_for_round(r: int) -> int:
	var A = 3    # starting enemies
	var B = 1  # scaling
	var k = 1.2  # curve strength
	
	return int(A + B * pow(r, k))

# =========================================
# SPAWN SYSTEM TUNING GUIDE
# =========================================

# --- WEIGHTS ---
# Weights are RELATIVE probabilities, not percentages.
# Each entry's chance = weight / total_weight
#
# Example:
#   goblin weight = 10
#   skeleton weight = 10
#   captain weight = 5
#   → total = 25
#   → goblin = 40%, skeleton = 40%, captain = 20%
#
# Increasing one weight makes ALL others less likely.

# Recommended ranges:
#   Common:    8–15
#   Uncommon:  4–8
#   Rare:      1–4

# --- MIN ROUND ---
# Controls WHEN an enemy/event appears.
# Do NOT use weight for progression—use min_round.

# --- ENEMY COUNT SCALING ---
# Formula: A + B * r^k
#
# A = base enemies (early rounds)
# B = scaling multiplier
# k = growth curve (difficulty ramp)
#
# Typical values:
#   A = 3
#   B = 1.0–2.0
#   k = 1.2–1.5

# --- EVENT COUNT ---
# Controls how many modifiers happen per round.
#
# Suggested:
#   rounds < 3   → 0 events
#   rounds 3–5   → 1 event
#   rounds 6–9   → 2 events
#   rounds 10+   → 3 events

# --- EVENT WEIGHTS ---
# Mild events:   6–10
# Strong events: 3–6
# Chaos events:  1–3

# --- DESIGN TIPS ---
# - Use min_round for progression
# - Use weight for frequency
# - Avoid making all weights equal
# - Avoid extreme values (100+ unnecessary)
# - Test late-game balance often
#
# Optional:
# Scale weights with round for dynamic difficulty:
#   weight += round * 0.5
#
# =========================================
