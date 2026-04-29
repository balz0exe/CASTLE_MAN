# upgrade_event.gd
# Raises a platform with four upgrade altars after each round.
# Player walks into an altar and presses interact to claim the upgrade.
# Signals upgrade_chosen when done so round_handler can continue.
extends RoundEvent

# =========================================
# VARIABLES
# =========================================

var final_height: float = 15
var height: float = 500
var up: bool = false
var original_height
var map
var label: Label
var totem_nodes: Array[UpgradeTotem]
var available_upgrades: Array  # upgrades offered this event, cleared each start
var upgrade_picked: bool = false  # blocks duplicate pickups from overlapping altar areas

# Master upgrade list — loaded in _ready so path errors are visible
var upgrades: Array[Dictionary] = []

signal upgrade_chosen

# =========================================
# READY
# =========================================

func _ready() -> void:
	Game.get_player().connect("interact_released", _on_interact_released)
	
	upgrades = [
		{name = "air roll", color = Color.CHARTREUSE, script = load("res://world/levels/round events/upgrades/upgrade_scripts/air_roll.gd"), weight = 2, cost = 20, stackable = false},
		{name = "double jump", color = Color.CHARTREUSE, script = load("res://world/levels/round events/upgrades/upgrade_scripts/double_jump.gd"), weight = 10, cost = 20, stackable = false},
		{name = "health up", color = Color.CRIMSON, script = load("res://world/levels/round events/upgrades/upgrade_scripts/health_up.gd"), weight = 12, cost = 20, stackable = true},
		{name = "stamina up", color = Color.CHARTREUSE, script = load("res://world/levels/round events/upgrades/upgrade_scripts/stamina_up.gd"), weight = 12, cost = 20, stackable = true},
		{name = "extra life", color = Color.CRIMSON, script = load("res://world/levels/round events/upgrades/upgrade_scripts/extra_life.gd"), weight = 4, cost = 40, stackable = true},
		{name = "attack up", color = Color.YELLOW, script = load("res://world/levels/round events/upgrades/upgrade_scripts/attack_up.gd"), weight = 6, cost = 30, stackable = true},
		{name = "armor up", color = Color.CRIMSON, script = load("res://world/levels/round events/upgrades/upgrade_scripts/armor_up.gd"), weight = 10, cost = 30, stackable = true},
		{name = "air throw", color = Color.YELLOW, script = load("res://world/levels/round events/upgrades/upgrade_scripts/air_throw.gd"), weight = 4, cost = 20, stackable = false},
		{name = "bounce damage", color = Color.YELLOW, script = load("res://world/levels/round events/upgrades/upgrade_scripts/bounce_damage.gd"), weight = 10, cost = 10, stackable = false},
		{name = "heal up", color = Color.CRIMSON, script = load("res://world/levels/round events/upgrades/upgrade_scripts/heal up.gd"), weight = 2, cost = 30, stackable = true},
		{name = "big roll", color = Color.CHARTREUSE, script = load("res://world/levels/round events/upgrades/upgrade_scripts/big_roll.gd"), weight = 6, cost = 20, stackable = false},
		{name = "iron grip", color = Color.YELLOW, script = load("res://world/levels/round events/upgrades/upgrade_scripts/iron_grip.gd"), weight = 2, cost = 40, stackable = false},
		{name = "goblin horde", color = Color.YELLOW, script = load("res://world/levels/round events/upgrades/upgrade_scripts/goblin_horde.gd"), weight = 1, cost = 40, stackable = true},
		{name = "a gun", color = Color.YELLOW, script = load("res://world/levels/round events/upgrades/upgrade_scripts/a_gun.gd"), weight = 0.5, cost = 100, stackable = true},
		{name = "exploding arrows", color = Color.YELLOW, script = load("res://world/levels/round events/upgrades/upgrade_scripts/exploding_arrows.gd"), weight = 2, cost = 40, stackable = false},
		{name = "thors blessing", color = Color.YELLOW, script = load("res://world/levels/round events/upgrades/upgrade_scripts/thors_hammer.gd"), weight = 2, cost = 50, stackable = false},
		{name = "sekhmet's staff", color = Color.YELLOW, script = load("res://world/levels/round events/upgrades/upgrade_scripts/sekhmet's staff.gd"), weight = 4, cost = 60, stackable = true},
	]

# =========================================
# WEIGHTED PICK
# Filters valid candidates before rolling so the loop can never freeze.
# Compares by name to avoid reference issues with mutated dictionaries.
# =========================================

func pick_weighted_upgrade() -> Dictionary:
	var pool: Array = upgrades.filter(func(u):
		# Non-stackables disappear permanently once the player has them
		if !u.stackable and manager.active_nonstackable_upgrades.has(u.name):
			return false
		# Never offer the same upgrade twice in one event
		if available_upgrades.any(func(a): return a.name == u.name):
			return false
		return true
	)

	if pool.is_empty():
		print("upgrade pool empty — add more upgrades to the list")
		pool = upgrades

	var total_weight: float = 0.0
	for u in pool:
		total_weight += u.weight
	var roll = randf_range(0.0, total_weight)
	var cumulative: float = 0.0
	for u in pool:
		cumulative += u.weight
		if roll <= cumulative:
			return u

	return pool[-1]

# =========================================
# START
# =========================================

func start(value):
	totem_nodes.clear()
	available_upgrades.clear()  # always start fresh regardless of prior state
	upgrade_picked = false       # reset pick guard each event
	current_area = null
	super(value)
	manager.upgrade_event = true
	map = load("res://world/levels/round events/upgrades/upgrade_tilemap.tscn")
	map = map.instantiate()
	label = map.get_child(-1)
	map.global_position = Vector2(0, height + 30)
	manager.get_parent().add_child(map)

	# Assign a unique weighted upgrade to each of the 4 altar slots
	# Duplicate the dictionary so the master upgrades array is never mutated
	for i in range(4):
		var u = pick_weighted_upgrade().duplicate()
		available_upgrades.append(u)
		u.node = map.get_child(i)
		u.node.fire.emitting = false
		u.node.fire.get_child(0).emitting = false
		u.node.body_entered.connect(on_upgrade_area_entered.bind(u.node))
		var upgrade = Powerup.new()
		upgrade.set_script(u.script)
		u.node.modulate = u.color
		u.node.upgrade = upgrade
		u.node.name = u.name
		u.node.cost = u.cost
		totem_nodes.append(u.node)

	raise()

# =========================================
# RAISE — moves the platform up into view
# =========================================

func raise():
	up = true
	original_height = height
	for i in range((original_height - final_height) / 5):
		height -= 5
		await Game.wait_for_seconds(0.05)
		Game.camera_shake(0.1, 1)
	for node in totem_nodes:
		node.fire.emitting = true
		node.fire.visible = true
		node.fire.get_child(0).emitting = true

# =========================================
# LOWER — moves the platform back down and cleans up objects
# =========================================

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
		# Toss any weapons that were sitting on the platform
		for o in Game.get_objects():
			if o.is_in_group("weapons"):
				o.apply_impulse(Vector2(0, -10))
	manager.upgrade_event = false
	await Game.wait_for_seconds(0.05)

# =========================================
# CLEAN UP
# =========================================
func clean_up():
	Game.get_player().disconnect("interact_released", _on_interact_released)
	for node in totem_nodes:
		node.reset()
	await lower()
	print("free map")
	queue_free()

# =========================================
# UPGRADE INTERACTION
# Player walks into an altar and presses interact to claim the upgrade.
# upgrade_picked flag blocks any other altar from firing once a choice is made.
# Emits upgrade_chosen so round_handler knows to continue.
# =========================================

var current_area: UpgradeTotem = null  # tracks which altar is currently displaying

func _on_interact_released():
	if !up or !Game.get_player().interaction_active:
		return
	if !upgrade_picked and Game.get_player().interaction_active and current_area != null:
		if Game.get_player().coins >= current_area.cost:
			Game.get_player().coins -= current_area.cost
			upgrade_picked = true
			print("added upgrade " + current_area.name)
			Game.get_player().add_child(current_area.upgrade)
			if !current_area.stackable:
				manager.active_nonstackable_upgrades.append(current_area.name)
			label.text = ""
			upgrade_chosen.emit()
			for node in totem_nodes:
				node.fire.emitting = false
				node.fire.get_child(0).emitting = false
				Game.fade_out_sprite(node)
			return
		else:
			upgrade_picked = true
			Game.get_player().take_damage(0, current_area)
			label.text = ""
			upgrade_chosen.emit()
			for node in totem_nodes:
				node.fire.emitting = false
				node.fire.get_child(0).emitting = false
				Game.fade_out_sprite(node)
			return

func on_upgrade_area_entered(body: Node2D, area: UpgradeTotem) -> void:
	if !up or !body.is_in_group("player"):
		return
	current_area = area
	var player = Game.get_player()
	player.interaction_active = true
	while area.get_overlapping_bodies().has(body) and !upgrade_picked and up:
		await Game.wait_for_seconds(get_physics_process_delta_time())
		if current_area == area:
			label.text = area.name + " " + str(area.cost) + " [f]"
	# Player left without choosing or another altar took over
	if current_area == area:
		current_area = null
		player.interaction_active = false
		label.text = ""

# =========================================
# PHYSICS PROCESS
# Moves the map to follow height each frame
# =========================================

func _physics_process(delta: float) -> void:
	super(delta)
	if map != null:
		map.global_position = Vector2(0, height + 30)
	if !manager.upgrade_event:
		return
