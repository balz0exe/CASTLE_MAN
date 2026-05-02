extends Node

#GAME WORLD VARIABLES
var GRAVITY: int = 800
var COLOR: Color = Color(1, 0.8, 0.8)

# SFX pooling
var sfx_pool: Array[AudioStreamPlayer2D] = []
var sfx_volume: int = -9

# Music
var music: bool = true
var level: Node2D
@onready var music_player_a = $MusicPlayer_1
@onready var music_player_b = $MusicPlayer_2
@onready var camera
@onready var fade = $CanvasLayer/FadeScreen
var active_player = null
var inactive_player = null
var current_music_path := ""
var fade_time := 1.0  # seconds
var low_health_threshold: int = 30
var low_pass_cutoff: float = 1200.0
var normal_cutoff: float = 22000.0

var is_ready = false
signal not_ready

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	level = get_level()
	is_ready = true
	await wait_for_seconds(1)
	fade_out_sprite(fade, 3)

func go_to_scene(next_scene: PackedScene) -> void:
	var player = get_player()
	var weapon
	if player.weapon != null:
		weapon = player.weapon.weapon
	await fade_in_sprite(fade)
	print("->faded out.")
	if next_scene:
		await get_tree().process_frame
		await get_tree().process_frame
		get_tree().change_scene_to_packed(next_scene)
		print("->changed scene.")
	else:
		push_error("Invalid scene passed to go_to_scene()")
		return
	
	# Wait for the scene to be ready
	await get_tree().process_frame
	await get_tree().process_frame  # Add a second frame to be safe
	print("waiting for level...")
	while get_level() == null:
		await get_tree().process_frame
	print("level found")
	
	while get_player() == null:
		await get_tree().process_frame
	if get_level().name != "MainLevel": get_player().equip_weapon(weapon, WeaponPickup.new())

	await fade_out_sprite(fade)

func _on_node_added(node: Node) -> void:
	if node.is_in_group("LevelScene"):
		level = node
		sfx_pool.clear()  # old sfx players are gone, reset the pool
		current_music_path = ""  # force music to reload
		play_level_music()

func get_level() -> Node2D:
	if not is_instance_valid(level):
		level = get_tree().get_first_node_in_group("LevelScene")
	return level

func _physics_process(delta: float) -> void:
	if pause_timer > 0:
		pause_timer -= 1 * delta

func wait_for_seconds(seconds: float) -> Signal:
	if is_ready and seconds != 0:
		var timer: Timer = Timer.new()
		timer.wait_time = seconds
		timer.one_shot = true
		get_level().call_deferred("add_child", timer)
		timer.autostart = true
		return timer.timeout
	return not_ready

func restart():
	get_tree().reload_current_scene()

func wait_until(condition_func: Callable) -> void:
	while not condition_func.call():
		await get_tree().process_frame

func get_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null
	
func get_game_handler() -> Node:
	var players = get_tree().get_nodes_in_group("roundhandler")
	if players.size() > 0:
		return players[0]
	return null

func get_characters() -> Array[CharacterBody2D]:
	var result: Array[CharacterBody2D] = []

	for n in get_tree().get_nodes_in_group("player"):
		if n is CharacterBody2D:
			result.append(n)

	for n in get_tree().get_nodes_in_group("enemies"):
		if n is CharacterBody2D:
			result.append(n)

	return result
	
func get_objects() -> Array[Node2D]:
	var result: Array[Node2D] = []

	for n in get_tree().get_nodes_in_group("objects"):
		if n is Node2D:
			result.append(n)

	return result

func camera_shake(duration: float, intensity: float) -> void:
	if not is_instance_valid(camera):
		return
	var original_offset: Vector2 = camera.offset
	var elapsed: float = 0.0
	while elapsed < duration:
		var delta = get_process_delta_time()
		camera.offset = original_offset + Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		elapsed += delta
		await get_tree().process_frame
	camera.offset = original_offset

func play_level_music():
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_method("get_music_path") and music:
		var path: String = current_scene.get_music_path()
		if not path == current_music_path:
			current_music_path = path
			var stream: AudioStream = load(path)
			if stream:
				_crossfade_to(stream)

func _crossfade_to(new_stream: AudioStream):
	# Swap active/inactive players
	if active_player == null:
		active_player = music_player_a
		inactive_player = music_player_b
	else:
		var temp = active_player
		active_player = inactive_player
		inactive_player = temp

	# Start the new stream on the new active player
	active_player.stream = new_stream
	active_player.volume_db = -40
	active_player.play()

	# Tween the volumes
	var tween := create_tween()
	tween.tween_property(active_player, "volume_db", -12, fade_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(inactive_player, "volume_db", -40, fade_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await tween.finished
	inactive_player.stop()
	inactive_player.stream = null

var pause_timer: float = 0.0
var pause_cooldown: float = 0.3

func hit_pause(duration: float = 0.1, pause_scale: float = 0.6, ignore_timer: bool = false) -> void:
	if pause_timer <= 0.0 or ignore_timer:
		await wait_for_seconds(0.01)
		Engine.time_scale = pause_scale
		await get_tree().create_timer(duration, true).timeout
		pause_timer = pause_cooldown
		Engine.time_scale = 1.0


var claimed_pickups: Dictionary = {}
func claim_pickup(pickup: WeaponPickup) -> bool:
	if claimed_pickups.has(pickup.get_instance_id()):
		#print("CLAIM REJECTED: ", pickup.get_instance_id())
		return false
	#print("CLAIM ACCEPTED: ", pickup.get_instance_id())
	claimed_pickups[pickup.get_instance_id()] = true
	return true

func release_pickup(pickup: WeaponPickup) -> void:
	claimed_pickups.erase(pickup.get_instance_id())

func spawn_object(object: Resource, global_position: Vector2) -> Node2D:
	if !object.is_class("PackedScene"):
		var weapon = WeaponPickup.new()
		weapon.res = object
		level.call_deferred("add_child", weapon)
		weapon.global_position = global_position
		weapon.apply_impulse(Vector2(0, -10))
		weapon.apply_torque(10)
		return weapon
	else:
		var _drop = object.instantiate()
		_drop.global_position = global_position
		level.add_child(_drop)
		return _drop

func spawn_particle_oneshot(fx: String, from: Node2D, offset: Vector2 = Vector2.ZERO, color = null, behind_parent: bool = true) -> Node2D:
	var particles = load(fx)
	particles = particles.instantiate()
	from.call_deferred("add_child", particles)
	if behind_parent:
		particles.z_index = -2
	else:
		particles.z_index = 1
	if color != null:
		particles.color = color
	if from.get("direction") != null:
		particles.position = Vector2(offset.x * from.direction, offset.y)
	else:
		particles.position = offset
	return particles

func spawn_explosion(from: Node2D, radius: int = 30, damage: int = 10, knockback: float = 50, damage_from: bool = false):
	var explosion = load("res://world/misc/explosion/explosion.tscn")
	explosion = explosion.instantiate()
	explosion.damage_from = damage_from
	call_deferred("explode", from, radius, damage, knockback, explosion)
	play_sfx(load("res://fx/audio_fx/fireball_shoot.wav"), sfx_volume + 8, from)
	
func explode(from, radius, damage, knockback, explosion):
	level.add_child(explosion)
	explosion.from = from
	explosion.global_position = from.global_position
	explosion.explode(radius, damage, knockback)

func tween_camera_position(_camera: Camera2D, position: Vector2, duration: float = 0.5) -> Tween:
	var tween = create_tween()
	tween.tween_property(_camera, "position", position, duration)
	return tween

var active_spins: Array[Node2D] = []
func animate_spining(sprite: Node, strength: float = 20):
	if active_spins.has(sprite):
		return
	var tween = create_tween()
	var original_pos = sprite.scale
	active_spins.append(sprite)

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(sprite, "scale", Vector2(-original_pos.x,original_pos.y), 100/strength)
	tween.tween_property(sprite, "scale", Vector2(original_pos.x,original_pos.y), 100/strength)

	await tween.finished
	
	if is_instance_valid(sprite):
		active_spins.erase(sprite)

var active_floats: Array[Node2D] = []

func animate_floating(node: Node, amplitude: float = 5.0, speed: float = 2.0) -> void:
	if active_floats.has(node):
		return
	active_floats.append(node)
	var tween = node.create_tween()  # tween owned by the node, dies with it
	var origin_y: float = node.position.y
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_loops()
	tween.tween_property(node, "position:y", origin_y + amplitude, 1.0 / speed)
	tween.tween_property(node, "position:y", origin_y - amplitude, 1.0 / speed)

func stop_floating(node: Node) -> void:
	active_floats.erase(node)
	# tween will keep running — call this if you need to kill it externally
	# store the tween ref if you need to kill it on demand

var active_bounces: Array[Node2D] = []
func animate_bouncing(sprite: Node2D, strength: float = 10):
	if active_bounces.has(sprite):
		return
	var tween = create_tween()
	var original_pos = sprite.offset
	active_bounces.append(sprite)

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(sprite, "offset", original_pos + Vector2(0, -strength), 0.1)
	tween.tween_property(sprite, "offset", original_pos, 0.1)

	await tween.finished
	
	if is_instance_valid(sprite):
		active_bounces.erase(sprite)

func fade_out_sprite(sprite: CanvasItem, duration: float = 0.5, to: float = 0):
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", to, duration)
	await tween.finished
	
func fade_in_sprite(sprite: CanvasItem, duration: float = 0.5, to: float = 1.0):
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", to, duration)
	await tween.finished

func get_available_sfx_player() -> AudioStreamPlayer2D:
	for sfx_player in sfx_pool:
		if not sfx_player.playing:
			return sfx_player
	# If all are playing, create a fallback
	var fallback := AudioStreamPlayer2D.new()
	fallback.bus = "SFX"
	fallback.connect("finished", _on_sfx_finished.bind(fallback))
	level.add_child(fallback)
	sfx_pool.append(fallback)
	return fallback

signal sfx_finished
func play_sfx(stream: AudioStream, db: float, origin_node: Node2D = null, pitch_randomization: bool = true, randomization: Vector2 = Vector2(0.80, 1.20)) -> Signal:
	var sfx_player: AudioStreamPlayer2D = get_available_sfx_player()
	sfx_player.bus = "Sfx"
	sfx_player.stream = stream
	sfx_player.volume_db = db
	sfx_player.pitch_scale = randf_range(randomization.x, randomization.y) if pitch_randomization else 1.0
	sfx_player.global_position = origin_node.global_position if origin_node else Vector2.ZERO
	sfx_player.play()
	await sfx_player.finished
	return sfx_finished
	
func play_sfx_pitched(stream: AudioStream, db: float, origin_node: Node2D = null, pitch: float = 1.0, pitch_randomization: bool = true) -> Signal:
	var sfx_player: AudioStreamPlayer2D = get_available_sfx_player()
	sfx_player.bus = "Sfx"
	sfx_player.stream = stream
	sfx_player.volume_db = db
	sfx_player.pitch_scale = pitch if !pitch_randomization else pitch * randf_range(0.80, 1.20)
	sfx_player.global_position = origin_node.global_position if origin_node else Vector2.ZERO
	sfx_player.play()
	await sfx_player.finished
	return sfx_finished

func _on_sfx_finished(sfx_player: AudioStreamPlayer2D) -> void:
	sfx_player.stop()
	sfx_player.stream = null

func update_music_filter(health: int, max_health: int) -> void:
	var music_bus_index: int = AudioServer.get_bus_index("Music")
	var filter: AudioEffectLowPassFilter = AudioServer.get_bus_effect(music_bus_index, 0)
	if not filter:
		return

	var health_percent: float = clamp(health / float(max_health), 0.0, 1.0)
	if health_percent <= low_health_threshold / 100.0:
		filter.cutoff_hz = low_pass_cutoff
	else:
		filter.cutoff_hz = normal_cutoff
