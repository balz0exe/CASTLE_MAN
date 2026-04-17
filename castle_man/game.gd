extends Node

#GAME WORLD VARIABLES
var GRAVITY: int = 800

# SFX pooling
var sfx_pool: Array[AudioStreamPlayer2D] = []
var sfx_volume: int = -9

# Music
var music: bool = true
@onready var music_player_a = $MusicPlayer_1
@onready var music_player_b = $MusicPlayer_2
@onready var camera
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
	is_ready = true

func _physics_process(delta: float) -> void:
	if pause_timer > 0:
		pause_timer -= 1 * delta

func wait_for_seconds(seconds: float) -> Signal:
	if is_ready:
		var timer: Timer = Timer.new()
		timer.wait_time = seconds
		timer.one_shot = true
		add_child(timer)
		timer.start()
		return timer.timeout
	return not_ready

func wait_until(condition_func: Callable) -> void:
	while not condition_func.call():
		await get_tree().process_frame

func get_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

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

func spawn_particle_oneshot(fx: String, from: Node2D, offset: Vector2 = Vector2.ZERO, color = null, behind_parent: bool = true) -> void:
	var particles = load(fx)
	particles = particles.instantiate()
	from.add_child(particles)
	particles.show_behind_parent = behind_parent
	if color != null: particles.color = color
	particles.global_position = from.global_position + offset

func spawn_explosion(from: Node2D, radius: int = 30, damage: int = 10, knockback: float = 50):
	var explosion = load("res://world/misc/explosion/explosion.tscn")
	explosion = explosion.instantiate()
	call_deferred("explode", from, radius, damage, knockback, explosion)
	play_sfx(load("res://fx/audio_fx/fireball_shoot.wav"), sfx_volume + 8, from)
	
func explode(from, radius, damage, knockback, explosion):
	add_child(explosion)
	explosion.global_position = from.global_position
	explosion.explode(radius, damage, knockback)

func tween_camera_position(_camera: Camera2D, position: Vector2, duration: float = 0.5) -> Tween:
	var tween = create_tween()
	tween.tween_property(_camera, "position", position, duration)
	return tween

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

func fade_out_sprite(sprite: Node2D, duration: float = 0.5):
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, duration)
	await tween.finished
	
func fade_in_sprite(sprite: Node2D, duration: float = 0.5):
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 100, duration)
	await tween.finished

func get_available_sfx_player() -> AudioStreamPlayer2D:
	for sfx_player in sfx_pool:
		if not sfx_player.playing:
			return sfx_player
	# If all are playing, create a fallback
	var fallback := AudioStreamPlayer2D.new()
	fallback.bus = "SFX"
	fallback.connect("finished", _on_sfx_finished.bind(fallback))
	add_child(fallback)
	sfx_pool.append(fallback)
	return fallback

signal sfx_finished
func play_sfx(stream: AudioStream, db: float, origin_node: Node2D = null, pitch_randomization: bool = true) -> Signal:
	var sfx_player: AudioStreamPlayer2D = get_available_sfx_player()
	sfx_player.stream = stream
	sfx_player.volume_db = db
	sfx_player.pitch_scale = randf_range(0.80, 1.20) if pitch_randomization else 1.0
	sfx_player.global_position = origin_node.global_position if origin_node else Vector2.ZERO
	sfx_player.play()
	await sfx_player.finished
	return sfx_finished
	
func play_sfx_pitched(stream: AudioStream, db: float, origin_node: Node2D = null, pitch: float = 1.0, pitch_randomization: bool = true) -> Signal:
	var sfx_player: AudioStreamPlayer2D = get_available_sfx_player()
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
