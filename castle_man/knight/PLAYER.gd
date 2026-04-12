#player.gd
extends CharacterBody2D

@onready var animation = $AnimatedSprite2D
@onready var coll = $CollisionShape2D
@onready var debug = $debug
@onready var player_ref = self
@onready var weapon_hand = $weapon_hand
@onready var hit_box = $HitBox
@onready var hurt_box = $HurtBox
@onready var camera = $Camera2D
@onready var shadow = $Shadow
var state_machine = Node
var state_version: int = 0

#PLAYER SFX

var jump_sfx: AudioStream = load("res://fx/audio_fx/player_jump.wav")
var hit_sfx: AudioStream = load("res://fx/audio_fx/sword_swing.wav")
var bounce_sfx: AudioStream = load("res://fx/audio_fx/bounce.wav")
var run_sfx: AudioStream = load("res://fx/audio_fx/foot_steps_.wav")
var run_sfx_2: AudioStream = load("res://fx/audio_fx/player_landing.wav")
var hurt_sfx: AudioStream = load("res://fx/audio_fx/player_hurt.wav")

#PLAYER STATS

var max_health = 100
var health = max_health
var dead = false
var max_stamina: float = 100
var stamina: float = max_stamina
var stamina_regen: float = 10

#COMBAT VARIABLES

var weapon: WeaponItem = null
var hits_taken: int = 0
var damage_on_bounce: bool = false
var bounce_damage: float = 2
var throw_path: String
var animations: Array[String]
var has_weapon: bool = false
var parry: bool = false
var combo_count: = 4
var combo_counter: int = 0
var combo_cooldown: float = 0.7
var combo_cooldown_timer: float = 0.0
var combo_reset_timer: float = 0.0
var held_frame_counter: float = 0.0
var held_frames: float = 0.35
var is_throw: bool = false
var invincible: bool = false
var invincible_time: float = 0.5
var invincible_timer: float = 0.0

#MOVEMENT VARIABLES

var acceleration = 350
var direction: int = 1
var knockback_force: int
var knockback_recovery = 0.35
var knocked_back: bool = false
var recovery_timer = 0.0
var sprint = false
var friction = 20
var max_speed = 125
var sprint_factor = 1.8
var prev_speed = max_speed
var jump_strength = -300
var roll_distance = 30
var roll_stam_cost = 10
var coyote_time = 0.2
var coyote_timer = 0.0
var in_air = false
var flip_h = false
var can_air_roll = false
var has_air_rolled = false
var can_double_jump = false
var has_double_jumped = false
var jumps : int = 0
var can_air_throw = false

func _ready() -> void:
	state_machine = $StateMachine
	state_machine.init(player_ref)
	shadow.visible = true
	can_air_roll = true
	can_double_jump = true
	can_air_throw = true
	damage_on_bounce = true
	
	Game.camera = camera


func _physics_process(delta: float) -> void:
	#debug

	if Input.is_action_just_pressed("ui_1"):
		can_air_roll = true
		can_double_jump = true
		can_air_throw = true
		damage_on_bounce = true
	elif Input.is_action_just_pressed("ui_2"):
		can_air_roll = false
		can_double_jump = false
		can_air_throw = false
		damage_on_bounce = false

	debug.text = str(combo_reset_timer)

	#check for death

	if health <= 0:
		die()

	#update animations and sound

	update_animations()
	Game.update_music_filter(health, max_health)
	
	#sprint

	if sprint and stamina > 0:
		max_speed = prev_speed * sprint_factor
	else:
		max_speed = prev_speed
	
	#stamina
	
	if state_machine.current_state.get_state_name() != "AttackState":
		if stamina < max_stamina:
			if sprint != true:
				if stamina < 0: stamina = 0
				stamina += stamina_regen * delta
		else:
			stamina = max_stamina
	
	#check direction

	if velocity.x > 0:
		flip_h = false
	elif velocity.x < 0:
		flip_h = true
	if flip_h:
		direction = -1
	else:
		direction = 1

	#hurt box collisions

	if animation.animation.contains("attack") and animation.frame == 1:
		hit_box.coll.disabled = false
	else:
		hit_box.coll.disabled = true

	#gravity and air roll

	if not is_on_floor():
		velocity.y += Game.GRAVITY * delta
		if  coyote_timer <= 0 and in_air == false:
			coyote_timer = coyote_time
			in_air = true
		if velocity.y > 10 and not (animation.animation.contains("attack") or animation.animation.contains("roll")):
			if !dead: state_machine.change_state("FallState")
	else:
		jumps = 0
		in_air = false
		has_air_rolled = false
		has_double_jumped = false
	if coyote_timer > 0:
		coyote_timer -= 1 * delta
	
	#combat state changes

	if Input.is_action_just_pressed("drop_item"):
		disarm()

	if has_weapon:
		if Input.is_action_pressed("attack"):
			held_frame_counter += 1 * delta
			if held_frame_counter > held_frames:
				if is_on_floor() and (weapon.throwable or weapon.ranged):
					if !dead: state_machine.change_state("ThrowState")
				elif can_air_throw and (weapon.throwable or weapon.ranged):
					if !dead: state_machine.change_state("ThrowState")
		if Input	.is_action_just_released("attack"):
			held_frame_counter = 0

	if invincible:
		hurt_box.coll.disabled = true
	else:
		hurt_box.coll.disabled = false
	#combat timers
	if invincible_timer > 0.0:
		invincible_timer -= delta * 1
	else:
		invincible = false
		invincible_timer = 0
	if combo_cooldown_timer > 0.0:
		combo_cooldown_timer -= delta * 1
	else:
		combo_cooldown_timer = 0
	if combo_reset_timer > 0.0:
		combo_reset_timer -= delta * 1
	else:
		combo_reset_timer = 0
	if recovery_timer > 0.0:
		recovery_timer -= delta * 1
	else:
		recovery_timer = 0
	if recovery_timer < 0:
		hits_taken = 0
	
	#update state machine Input and apply motion
	
	state_machine.current_state.update_input()
	var current = state_machine.current_state.get_state_name()
	if not current == "AttackState" and not current == "RollState" and not current == "HurtState":
		velocity.x = clamp(velocity.x, -max_speed, max_speed)
	move_and_slide()
	
func set_attack_pattern(combo: int, anim: Array[String]):
	combo_count = combo
	animations = anim
	
func update_animations() -> void:
	state_machine.current_state.update_animation()
	if animation.animation == "attack up" or animation.animation == "attack down" or (animation.animation == "fall" and knocked_back):
		animation.flip_h = !flip_h
	else:
		animation.flip_h = flip_h
	if weapon != null:
		weapon.sync_with_animation(animation.animation, animation.frame, flip_h)

var blood_path = "res://fx/particle_fx/blood_particles.tscn"

func take_damage(damage, from: Node2D, knockback: float = 10):
	if !dead and !invincible:
		if parry:
			from.parried(self)
			return
		health = health - damage
		Game.spawn_particle_oneshot(blood_path, self, Vector2(-direction * 5, -10))
		var knock_back_direction = -sign(from.global_position.x - global_position.x)
		knockback_force = 15 * knockback * knock_back_direction
		if state_machine.current_state.get_state_name() == "HurtState":
			hits_taken += 1
			state_machine.current_state.retrigger()
		else:
			hits_taken += 1
			state_machine.change_state("HurtState")

signal player_respawned
func respawn() -> void:
	player_respawned.emit()
	health = max_health
	rotation = 0
	dead = false
	coll.disabled = false
	state_machine.change_state("IdleState")
	global_position = Vector2.ZERO

func disarm():
	if weapon:
		var drop = load(weapon.throw_path)
		await get_tree().process_frame
		if drop != null:
			drop = drop.instantiate()
			drop.global_position = global_position
			drop.apply_impulse(Vector2(0, -10))
			drop.apply_torque(-direction * 10)
			get_parent().add_child(drop)
			has_weapon = false
			weapon.call_deferred("queue_free")

signal player_died
func die() -> void:
	if dead == false:
		player_died.emit()
		dead = true
		var drop
		if weapon:
			drop = load(weapon.throw_path)
		if drop != null:
			drop = drop.instantiate()
			drop.global_position = global_position
			drop.apply_impulse(Vector2(0, -10))
			drop.apply_torque(-direction * 10)
			get_parent().add_child(drop)
		if shadow: shadow.visible = false
		state_machine.change_state("DieState")

var pending_weapon_scene: PackedScene = null
var pending_pickup_scene: RigidBody2D = null

func equip_weapon(weapon_scene: PackedScene, pickup_scene: RigidBody2D):
	# Just store the latest request
	pending_weapon_scene = weapon_scene
	pending_pickup_scene = pickup_scene
	# Schedule the actual equip for the end of the frame
	call_deferred("_do_equip")

var weapon_hit_box_reach_offset: int

func _do_equip():
	if not pending_weapon_scene:
		return
		
	weapon = pending_weapon_scene.instantiate()
	pending_pickup_scene.queue_free()
	# ... rest of your setup ...
	
	# Clear the pending status so it doesn't run again unless called
	has_weapon = true
	hit_box.get_child(0).shape = weapon.get_child(0).shape
	weapon_hit_box_reach_offset = weapon.get_child(0).position.x
	weapon.set_meta("resource_path", pending_weapon_scene.resource_path)
	pending_weapon_scene = null
	pending_pickup_scene = null
	weapon.owner_player = self
	weapon_hand.add_child(weapon)
	weapon.on_equip(self)
