extends RoundEvent

# --- CONFIG ---
var cast_count: int = 20          # number of raycast columns across the screen
var strike_interval_min: float = 0.4
var strike_interval_max: float = 1.2
var warning_duration: float = 0.5  # time the warning indicator shows before strike
var damage: int = 25
var knockback: float = 200.0
var spawn_area_width: float = 900

# --- STATE ---
var running := true
var space_state: PhysicsDirectSpaceState2D

func start(value):
	super.start(value)
	space_state = manager.get_tree().current_scene.get_world_2d().direct_space_state
	run()

func run() -> void:
	while running:
		if round_id != manager.current_round_id:
			queue_free()
			return

		var delay = randf_range(strike_interval_min, strike_interval_max)
		# Scale strikes to become more frequent as rounds progress
		delay = max(delay - (manager._round * 0.015), 0.2)
		await manager.get_tree().create_timer(delay).timeout

		if running:
			trigger_strike()

# --- CORE BEHAVIOR ---
func trigger_strike() -> void:
	# Pick a random X column across the spawn width
	var x = randf_range(-spawn_area_width, spawn_area_width)

	# Raycast from top of screen downward
	var ray_from = Vector2(x, -600)
	var ray_to = Vector2(x, 800)

	var query = PhysicsRayQueryParameters2D.create(ray_from, ray_to)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)

	if result.is_empty():
		return

	var hit_pos: Vector2 = result.position
	var collider = result.collider

	# Show a warning indicator at the hit position, then strike
	show_warning(hit_pos)
	await manager.get_tree().create_timer(warning_duration).timeout

	if not running:
		return

	# Spawn lightning particles at the hit position
	spawn_lightning(hit_pos)

	# Deal damage if we hit a character directly
	if collider.is_in_group("player") or collider.is_in_group("enemies"):
		apply_lightning_hit(collider, hit_pos)
	else:
		# Hit environment — do an overlap check for nearby characters
		check_area_damage(hit_pos)

func show_warning(pos: Vector2) -> void:
	var level = Game.get_level()
	if not is_instance_valid(level):
		return

	var warning = ColorRect.new()
	warning.size = Vector2(4, 600)
	warning.color = Color(1.0, 1.0, 0.3, 0.35)
	warning.position = Vector2(pos.x - 2, pos.y - 600)
	level.add_child(warning)

	# Flicker the warning
	var tween = warning.create_tween()
	tween.set_loops(int(warning_duration / 0.1))
	tween.tween_property(warning, "modulate:a", 0.1, 0.05)
	tween.tween_property(warning, "modulate:a", 1.0, 0.05)
	await manager.get_tree().create_timer(warning_duration).timeout
	if is_instance_valid(warning):
		warning.queue_free()

func spawn_lightning(pos: Vector2) -> void:
	# Main ground burst particles
	Game.spawn_particle_oneshot(
		"res://fx/particle_fx/lightning/lightning.tscn",
		Game.get_level(),
		pos,
		Color(0.6, 0.8, 1.0)
	)
	# Camera shake
	Game.camera_shake(0.2, 5.0)
	# SFX — swap path for your actual thunder/zap sound
	Game.play_sfx(load("res://fx/audio_fx/lightning_strike.wav"), Game.sfx_volume)

func apply_lightning_hit(character: Node2D, pos: Vector2) -> void:
	if character.has_method("take_damage"):
		character.take_damage(damage, knockback, pos)
	Game.spawn_particle_oneshot(
		"res://fx/particle_fx/lightning/lightning.tscn",
		Game.get_level(),
		character.global_position,
		Color(0.6, 0.8, 1.0)
	)
	Game.camera_shake(0.25, 7.0)

func check_area_damage(pos: Vector2) -> void:
	# Check a small radius around the ground hit for nearby characters
	var hit_radius: float = 40.0
	for character in Game.get_characters():
		if is_instance_valid(character):
			if character.global_position.distance_to(pos) <= hit_radius:
				apply_lightning_hit(character, pos)

# --- CLEANUP ---
func clean_up():
	running = false
