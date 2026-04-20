# player.gd
# The main player character. Handles input, physics, combat, and animation.
# Extends CharacterBody2D directly — but many properties here could move to character.gd
# if enemies and the player share a common base class in future.
extends CharacterBody2D

# =========================================
# NODE REFERENCES
# =========================================

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var coll: CollisionShape2D = $CollisionShape2D
@onready var debug: Label = $debug
@onready var player_ref = self
@onready var weapon_hand: Node2D = $weapon_hand
@onready var hit_box = $HitBox
@onready var soft_coll: Area2D = $SoftCollisionBubble
@onready var hurt_box = $HurtBox
@onready var camera: Camera2D = $Camera2D
@onready var shadow = $Shadow
@onready var light = $Glow

# =========================================
# AUDIO — could move to character.gd
# =========================================

var jump_sfx: AudioStream = load("res://fx/audio_fx/player_jump.wav")
var hit_sfx: AudioStream = load("res://fx/audio_fx/sword_swing.wav")
var bounce_sfx: AudioStream = load("res://fx/audio_fx/bounce.wav")
var run_sfx: AudioStream = load("res://fx/audio_fx/foot_steps_.wav")
var run_sfx_2: AudioStream = load("res://fx/audio_fx/player_landing.wav")
var hurt_sfx: AudioStream = load("res://fx/audio_fx/player_hurt.wav")

# =========================================
# STATS — could move to character.gd
# =========================================

var max_health: int = 50
var health: float = max_health
var lives: int = 3
var dead: bool = false
var max_stamina: float = 50
var stamina: float = max_stamina
var stamina_regen: float = 10

# =========================================
# COMBAT — partially shared with enemy.gd
# =========================================

var weapon: WeaponItem = null
var damage_factor: float = 1.0
var hurt_factor: float = 1.0
var hits_taken: int = 0
var damage_on_bounce: bool = false
var bounce_damage: float = 2
var animations: Array[String]
var has_weapon: bool = false
var has_boots: bool = false

# Combo system
var combo_count: int = 4
var combo_counter: int = 0
var combo_cooldown: float = 0.7
var combo_cooldown_timer: float = 0.0
var combo_reset_timer: float = 0.0

# Charge attack / throw
var held_frame_counter: float = 0.0
var held_frames: float = 0.35
var is_throw: bool = false

# Invincibility frames
var invincible: bool = false
var invincible_time: float = 0.8
var invincible_timer: float = 0.0

# =========================================
# MOVEMENT — could move to character.gd
# =========================================

var acceleration: float = 350
var direction: int = 1
var knockback_force: float = 0
var knockback_recovery: float = 0.35
var knocked_back: bool = false
var recovery_timer: float = 0.0
var sprint: bool = false
var friction: int = 10
var max_speed: float = 75
var sprint_factor: float = 1.8
var speed_potion: float = 1.0
var prev_speed: float = max_speed
var jump_strength: int = -300
var roll_distance: int = 10
var roll_stam_cost: int = 6

# Coyote time — allows jumping briefly after walking off a ledge
var coyote_time: float = 0.2
var coyote_timer: float = 0.0
var in_air: bool = false

var flip_h: bool = false
var can_bounce: bool = true

# Air movement options
var can_air_roll: bool = false
var has_air_rolled: bool = false
var can_double_jump: bool = false
var has_double_jumped: bool = false
var jumps: int = 0
var can_air_throw: bool = false

# Interaction input
var interaction_active: bool = false

# =========================================
# SIGNALS — could move to character.gd
# =========================================

signal ground_pound
signal hit(target)
signal player_died
signal player_respawned

# =========================================
# READY
# =========================================

func _ready() -> void:
	state_machine = $StateMachine
	state_machine.init(player_ref)

	Game.camera = camera
	lives = 3

	connect("ground_pound", on_ground_pound)
	connect("hit", on_hit)

	equip_weapon(load("res://world/objects/weapons/sword/sword.tres"))

# =========================================
# PHYSICS PROCESS
# =========================================

var state_machine = Node
var state_version: int = 0
var current_state: String

func _physics_process(delta: float) -> void:
	# --- Debug ---
	debug.text = str(collision_layer)

	# --- Death check ---
	if health <= 0:
		die()
		state_machine.change_state("DieState")

	# --- Animations and audio filter ---
	update_animations()
	Game.update_music_filter(health, max_health)

	# --- Sprint speed ---
	if sprint and stamina > 0:
		max_speed = prev_speed * sprint_factor * speed_potion
	else:
		max_speed = prev_speed * speed_potion

	# --- Stamina regen (not during attacks) ---
	if state_machine.current_state.get_state_name() != "AttackState":
		if stamina < max_stamina:
			if not sprint:
				stamina = clamp(stamina + stamina_regen * delta, 0, max_stamina)
		else:
			stamina = max_stamina

	# --- Direction from velocity ---
	if velocity.x > 0:
		flip_h = false
	elif velocity.x < 0:
		flip_h = true
	direction = -1 if flip_h else 1

	# --- Hitbox active only on attack frame 1 ---
	hit_box.coll.disabled = not (animation.animation.contains("attack") and animation.frame == 1)

	# --- Gravity and air state ---
	if not is_on_floor():
		velocity.y += Game.GRAVITY * delta
		if coyote_timer <= 0 and not in_air:
			coyote_timer = coyote_time
			in_air = true
		# Transition to fall state if moving downward and not in an overriding animation
		if velocity.y > 10 and not (animation.animation.contains("attack") or animation.animation.contains("roll")):
			if not dead:
				state_machine.change_state("FallState")
	else:
		jumps = 0
		in_air = false
		has_air_rolled = false
		has_double_jumped = false

	if coyote_timer > 0:
		coyote_timer -= delta

	# --- Drop weapon ---
	if Input.is_action_just_pressed("drop_item") and !interaction_active:
		disarm()

	# --- Charge throw input ---
	if has_weapon:
		if Input.is_action_pressed("attack"):
			held_frame_counter += delta
			if held_frame_counter > held_frames:
				if (is_on_floor() or can_air_throw) and (weapon.throwable or weapon.ranged):
					if not dead:
						state_machine.change_state("ThrowState")
		if Input.is_action_just_released("attack"):
			held_frame_counter = 0

	# --- Invincibility frames ---
	if invincible:
		if state_machine.current_state.get_state_name() != "RollState":
			blink()
		hurt_box.coll.disabled = true
		soft_coll.monitoring = false
	else:
		hurt_box.coll.disabled = false
		soft_coll.monitoring = true

	# --- Tick timers ---
	invincible_timer = max(invincible_timer - delta, 0)
	if invincible_timer == 0:
		invincible = false

	combo_cooldown_timer = max(combo_cooldown_timer - delta, 0)
	combo_reset_timer = max(combo_reset_timer - delta, 0)
	recovery_timer = max(recovery_timer - delta, 0)
	if recovery_timer == 0:
		hits_taken = 0

	# --- State machine input and movement ---
	state_machine.current_state.update_input()
	current_state = state_machine.current_state.get_state_name()
	if current_state not in ["AttackState", "RollState", "HurtState"]:
		velocity.x = clamp(velocity.x, -max_speed, max_speed)
	move_and_slide()

# =========================================
# COMBAT
# =========================================

func set_attack_pattern(combo: int, anim: Array[String]) -> void:
	combo_count = combo
	animations = anim

var blood_path: String = "res://fx/particle_fx/blood_particles.tscn"
var knock_back_direction: Vector2

func take_damage(damage: int, from: Node2D, knockback: float = 10) -> void:
	if dead:
		return
	health -= damage * hurt_factor
	Game.spawn_particle_oneshot(blood_path, self, Vector2(-direction * 5, -10))
	await get_knockback_direction(from)
	if knock_back_direction:
		knockback_force = 15 * knockback * knock_back_direction.x
	if state_machine.current_state.get_state_name() == "HurtState":
		hits_taken += 1
		state_machine.current_state.retrigger()
	else:
		hits_taken += 1
		state_machine.change_state("HurtState")

func get_knockback_direction(from: Node2D) -> void:
	if from == null:
		return
	var pos1: Vector2 = from.global_position
	await Game.wait_for_seconds(get_physics_process_delta_time())
	if not is_instance_valid(from):
		print("knockback failed — source freed before direction resolved")
		return
	var pos2: Vector2 = from.global_position
	knock_back_direction = -sign(pos1 - pos2)
	await Game.wait_for_seconds(get_physics_process_delta_time())

func disarm() -> void:
	if not weapon:
		return
	var drop = WeaponPickup.new()
	drop.res = weapon.weapon
	await Game.wait_for_seconds(get_physics_process_delta_time())
	get_parent().add_child(drop)
	drop.global_position = global_position
	drop.apply_impulse(Vector2(0, -10))
	drop.apply_torque(-direction * 10)
	has_weapon = false
	if weapon: weapon.call_deferred("queue_free")

# =========================================
# DEATH & RESPAWN — could move to character.gd
# =========================================

func die() -> void:
	if dead:
		return
	dead = true
	lives -= 1
	player_died.emit()

	# Drop weapon on death
	if weapon:
		var drop = WeaponPickup.new()
		drop.res = weapon.weapon
		get_parent().add_child(drop)
		drop.global_position = global_position
		drop.apply_impulse(Vector2(0, -10))
		drop.apply_torque(-direction * 10)

	if shadow:
		shadow.visible = false
	Game.fade_out_sprite(light, 1)

func respawn() -> void:
	invincible_timer = 3
	invincible = true
	health = max_health
	rotation = 0
	dead = false
	coll.disabled = false
	state_machine.change_state("IdleState")
	global_position = Vector2.ZERO
	if Game.get_game_handler().active_event_names.has("darkness"): Game.fade_in_sprite(light, 0.5, 0.3)
	else: Game.fade_in_sprite(light)
	animation.modulate.a = 1.0
	player_respawned.emit()

# =========================================
# WEAPON EQUIP
# =========================================

# Deferred equip system — stores the latest request and applies it end-of-frame
# to avoid equipping mid-physics-step
var pending_weapon_res: Resource = null
var pending_pickup_scene: RigidBody2D = null
var weapon_hit_box_reach_offset: Vector2

func equip_weapon(res: Resource, pickup: RigidBody2D = null) -> void:
	pending_weapon_res = res
	pending_pickup_scene = pickup
	call_deferred("_do_equip")

func _do_equip() -> void:
	if not pending_weapon_res:
		return
	weapon = WeaponItem.new()
	if pending_pickup_scene:
		pending_pickup_scene.queue_free()
	has_weapon = true
	hit_box.get_child(0).shape = pending_weapon_res.hurt_box_shape
	weapon_hit_box_reach_offset = pending_weapon_res.hurt_box_offset
	weapon.set_meta("resource_path", pending_weapon_res.resource_path)
	weapon.owner_player = self
	weapon_hand.add_child(weapon)
	weapon.on_equip(self, pending_weapon_res)
	pending_weapon_res = null
	pending_pickup_scene = null

# =========================================
# ANIMATION
# =========================================

func update_animations() -> void:
	state_machine.current_state.update_animation()
	# Attack and knockback animations flip opposite to movement direction
	if animation.animation in ["attack up", "attack down"] or (animation.animation == "fall" and knocked_back):
		animation.flip_h = !flip_h
	else:
		animation.flip_h = flip_h
	if weapon != null:
		weapon.sync_with_animation(animation.animation, animation.frame, flip_h)

# =========================================
# VFX
# =========================================

var blinking: bool = false

func blink() -> void:
	if blinking:
		return
	blinking = true
	await Game.fade_out_sprite(animation, 0.2, 0.5)
	await Game.fade_in_sprite(animation, 0.2)
	blinking = false

# =========================================
# SIGNAL CALLBACKS
# =========================================

func on_hit(_target: Node2D) -> void:
	pass

func on_ground_pound() -> void:
	pass
