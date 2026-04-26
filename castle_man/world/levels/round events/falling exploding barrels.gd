extends RoundEvent

# --- CONFIG ---
var spawn_delay: float = 3.0
var spawn_area_width: float = 900
var spawn_height: float = -200

# Add your weapon resources here
var weapon = load("res://world/objects/barrels/exploding_barrel.tscn")

# --- STATE ---
var running := true

func start(value):
	super.start(value)
	run()

func run() -> void:
	while running:
		# 🔥 Safety check (CRITICAL)
		if round_id != manager.current_round_id:
			queue_free()
			return

		spawn_weapon()

		# Scale spawn speed slightly with round
		var delay = max(spawn_delay - (manager._round * 0.1), 0.3)

		await manager.get_tree().create_timer(delay).timeout

# --- CORE BEHAVIOR ---
func spawn_weapon():
	if weapon == null:
		return

	var x = randf_range(-spawn_area_width, spawn_area_width)
	var pos = Vector2(x, spawn_height)

	var obj = Game.spawn_object(weapon, pos)

	# Optional: give it some variation
	if obj is RigidBody2D:
		obj.apply_impulse(Vector2(randf_range(-20, 20), randf_range(0, 20)))
		obj.apply_torque(randf_range(-10, 10))

# --- CLEANUP ---
func clean_up():
	running = false
