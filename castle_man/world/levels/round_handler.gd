# round_handler.gd
# Manages the game loop — spawning enemies, running events, and offering upgrades.
# Attached as a child of the level scene.
extends Node
class_name RoundHandler

# =========================================
# ROUND VARIABLES
# =========================================

var spawn_timer: float = 0
var spawn_time: float = 2
var _round: int = 1
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
	{ name = "falling weapons", script = load("res://world/levels/round events/falling_knives.gd"), weight = 4, min_round = 3 },
	{ name = "floor is lava", script = load("res://world/levels/round events/floor_is_lava/floor_is_lava.gd"), weight = 6, min_round = 5 },
	{ name = "falling barrels", script = load("res://world/levels/round events/falling_barrels.gd"), weight = 12, min_round = 2 },
	{ name = "falling exploding barrels", script = load("res://world/levels/round events/falling exploding barrels.gd"), weight = 4, min_round = 6 },
	{ name = "moon gravity", script = load("res://world/levels/round events/moon_gravity.gd"), weight = 5, min_round = 5 },
	{ name = "darkness", script = load("res://world/levels/round events/darkness/darkness.gd"), weight = 3, min_round = 2 },
	{ name = "storm", script = load("res://world/levels/round events/storm.gd"), weight = 3, min_round = 5 },
	#GARDEN (only mushrooms and sprouts)
	#BLOOD MOON (only hell hounds and necromancers)
]

# =========================================
# ENEMY DEFINITIONS
# Same weighted system as events
# =========================================

var enemies = [
	{ name = "goblin", scene = load("res://enemies/scenes/goblin.tscn"), weight = 4, min_round = 4 },
	{ name = "skeleton", scene = load("res://enemies/scenes/skeleton.tscn"), weight = 6, min_round = 2 },
	{ name = "captain", scene = load("res://enemies/scenes/goblin_captain.tscn"), weight = 2, min_round = 6 },
	{ name = "slime", scene = load("res://enemies/scenes/slime.tscn"), weight = 10, min_round = 1 },
	{ name = "mushroom", scene = load("res://enemies/scenes/mushroom.tscn"), weight = 8, min_round = 1 },
	{ name = "bat", scene = load("res://enemies/scenes/bat.tscn"), weight = 4, min_round = 2 },
	{ name = "fire sprout", scene = load("res://enemies/scenes/fire_sprout.tscn"), weight = 3, min_round = 3 },
	#OGRE (big high knockback slow)
	#HELL HOUND (fast quick attack)
	#NECROMANCER (avoids player summons skeletons)
	#LIGHTNING SPROUT (tries to spawn lightning on player)
	#GARGOYLE (flying enemy with weapons)
	#GOBLIN ON WARPIG (basic goblin but he comes in on a warpig you have to kill first)
	#GOBLIN BOMBER (runs at player and kamakatzis)
	#GOLEM (big high knockback slow throws rocks)
	#DARK KNIGHT (all around decent stats low spawn chance *mini boss)
]

# =========================================
# DROPS
# Same weighted system as events
# =========================================

var weapons = [
	[load("res://world/objects/weapons/axe/hand_axe.tres"), 15],
	[load("res://world/objects/weapons/sword/sword.tres"), 15],
	[load("res://world/objects/weapons/spear/spear.tres"), 10],
	[load("res://world/objects/weapons/great_sword/great_sword.tres"), 5],
	[load("res://world/objects/weapons/mace/mace.tres"), 8],
]

var drops = [
	[load("res://knight/powerups/exploding boots/exploding_boots.tres"), 5],
	[load("res://knight/powerups/lightning attacks/lightning_attack.tres"), 5],
	[load("res://knight/powerups/health potion/health_potion.tres"), 20],
	[load("res://knight/powerups/stamina potion/stamina_potion.tres"), 20],
	[load("res://enemies/scenes/slime.tscn"), 10],
	[load("res://world/objects/weapons/bow/bow.tres"), 8],
	[load("res://knight/powerups/mushroom friend/mushroom_friend.tres"), 5],
	[load("res://knight/powerups/weapons to coins/weapons_to_coins.tres"), 3],
	[load("res://knight/powerups/turn to slime/turn_to_slime.tres"), 3],
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
	new_round()
	call_deferred("spawn_start_objects")

func spawn_start_objects():
	var objects = [
		{ name = "barrel", scene = load("res://world/objects/barrels/barrel.tscn"), weight = 100},
		{ name = "exploding_barrel", scene = load("res://world/objects/barrels/exploding_barrel.tscn"), weight = 1},
	]
	for i in range(25):
		var d = pick_start_object(objects)
		var _name = d.name
		var object = d.scene
		object = object.instantiate()
		Game.get_level().add_child(object)
		print(object.name)
		if _name == "barrel":
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

func pick_weighted_weapon():
	var total_weight: float = 0.0
	for w in weapons:
		total_weight += w[1]
	var roll = randf_range(0.0, total_weight)
	var cumulative: float = 0.0
	for w in weapons:
		cumulative += w[1]
		if roll <= cumulative:
			return w[0]
	return weapons[-1][0]

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

func clear_events():
	if !active_events.is_empty():
		for e in active_events:
			e.queue_free()

func new_round():
	if not is_instance_valid(self):
		return

	await Game.wait_for_seconds(3)

	clear_events()

	_round += 1
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
	
	score += floori(_round*1.3)+9
	
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

func pick_enemy(_round_num: int) -> Dictionary:
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
			return e
	return available.back()

func spawn_enemy(_round_num: int, fall: bool = false) -> void:
	var pick = pick_enemy(_round_num)
	var scene = pick.scene
	
	var cam = Game.get_player().camera
	var cam_pos = cam.get_screen_center_position()
	var half_size = get_viewport().get_visible_rect().size / 2 / cam.zoom
	
	var pos: Vector2
	if fall:
		# Spawn along top edge, random x within screen bounds
		pos = Vector2(randf_range(cam_pos.x - half_size.x, cam_pos.x + half_size.x), cam_pos.y - half_size.y)
	else:
		# Spawn at left or right edge, random y within screen bounds
		var dir = [1, -1].pick_random()
		pos = Vector2(cam_pos.x + (half_size.x * dir), 112)

	var enemy: Enemy = Game.spawn_object(scene, pos)
	if pick.name == "skeleton":
		var ran = [1, -1].pick_random()
		if ran == 1:
			while is_instance_valid(enemy) == false:
				await get_tree().process_frame
			var weapon = pick_weighted_weapon()
			if is_instance_valid(enemy):
				enemy.equip_weapon(weapon, WeaponPickup.new())
	var ai = enemy.ENEMY_AI
	var round_id = current_round_id
	ai.enemy = Game.get_player()
	enemy.coin_weight = pick.weight
	enemy.died.connect(func(e): on_enemy_died(e, round_id))
	enem_count += 1
	print("spawned enemy " + str(enem_count))

func calc_coin_drop(player: CharacterBody2D, enemy: Enemy, round_num: int) -> int:
	# ---- TUNING KNOBS ----
	var base_coins: float = 0.0       # floor before any bonuses
	var rarity_scale: float = 2.5     # max bonus coins for rarest enemy
	var health_scale: float = 2.0     # max bonus coins for full health
	var round_scale: float = 3.0      # max bonus coins at round 20+
	var lives_scale: float = 1.0      # max bonus coins for having max lives
	var max_lives: int = 5            # your max lives cap
	# ----------------------

	# rarity: low spawn weight = rare = more coins
	var total_weight: float = 0.0
	for e in enemies:
		total_weight += e.weight
	var rarity: float = 1.0 - (enemy.coin_weight / total_weight)
	var rarity_bonus: float = rarity * rarity_scale

	# health: full hp = max bonus, 0 hp = no bonus
	var health_ratio: float = float(player.health) / float(player.max_health)
	var health_bonus: float = health_ratio * health_scale

	# round: logarithmic — fast early growth, tapers late
	var round_bonus: float = (log(max(1, round_num)) / log(20.0)) * round_scale

	# lives: more lives = more coins
	var lives_ratio: float = float(player.lives) / float(max_lives)
	var lives_bonus: float = lives_ratio * lives_scale

	var total: float = base_coins + rarity_bonus + health_bonus + round_bonus + lives_bonus
	return max(0, roundi(total))

func drop_coins(coins: int, from: Node2D):
	for c in range(coins):
		var coin = Game.spawn_object(load("res://knight/powerups/coins/coin.tres"), from.global_position)
		coin.apply_impulse(Vector2(randi_range(-200,200), randi_range(5,12))*Engine.time_scale)
		score += 1
	print("dropped "+str(coins)+" coins")

func on_enemy_died(enemy: Enemy, round_id: int) -> void:
	var coins = calc_coin_drop(Game.get_player(), enemy, _round)
	drop_coins(coins, enemy)
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
	var A = 8
	var B = 1.5
	var k = 1.2
	return int(A + B * pow(r, k))
