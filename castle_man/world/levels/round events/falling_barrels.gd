extends RoundEvent
# --- CONFIG ---
var spawn_delay: float = 1.0
var spawn_area_width: float = 900
var spawn_height: float = -200

var weapon = load("res://world/objects/barrels/barrel.tscn")
var drops = [
	[load("res://knight/powerups/exploding boots/exploding_boots.tres"), 5],
	[load("res://knight/powerups/health potion/health_potion.tres"), 20],
	[load("res://knight/powerups/speed potion/speed_potion.tres"), 20],
	[load("res://knight/powerups/stamina potion/stamina_potion.tres"), 20],
	[load("res://enemies/scenes/slime.tscn"), 10],
	[load("res://world/objects/weapons/axe/hand_axe.tres"), 15],
	[load("res://world/objects/weapons/sword/sword.tres"), 15],
	[load("res://world/objects/weapons/spear/spear.tres"), 10],
	[load("res://world/objects/weapons/bow/bow.tres"), 8],
	[load("res://world/objects/weapons/great_sword/great_sword.tres"), 5],
]

# --- STATE ---
var running := true

func start(value):
	super.start(value)
	run()

func run() -> void:
	while running:
		if round_id != manager.current_round_id:
			queue_free()
			return
		spawn_weapon()
		var delay = max(spawn_delay - (manager._round * 0.05), 0.3)
		await manager.get_tree().create_timer(delay).timeout

# --- CORE BEHAVIOR ---
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

func spawn_weapon():
	if weapon == null:
		return
	var x = randf_range(-spawn_area_width, spawn_area_width)
	var pos = Vector2(x, spawn_height)
	var obj = Game.spawn_object(weapon, pos)
	var ran = [1, -1].pick_random()
	if ran == 1:
		obj.drop = pick_weighted_drop()
	if obj is RigidBody2D:
		obj.apply_impulse(Vector2(randf_range(-20, 20), randf_range(0, 20)))
		obj.apply_torque(randf_range(-10, 10))

# --- CLEANUP ---
func clean_up():
	running = false
