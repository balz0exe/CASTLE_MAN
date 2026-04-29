# enemy.gd
# Base enemy character. Handles physics, combat, animation, and AI requests.
# Empty virtual functions at the bottom allow subclasses to extend behavior.
# Note: many variables here overlap with player.gd — good candidate for character.gd base class.
extends CharacterBody2D
class_name Enemy

# =========================================
# NODE REFERENCES
# =========================================

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var coll = $CollisionShape2D
@onready var debug = $debug
@onready var player_ref = self
@onready var weapon_hand = $weapon_hand
@onready var sight_cast = $SightCast
@onready var wall_cast = $WallCast
@onready var feet_cast = $FeetCast
@onready var platform_cast = $PlatformCast
@onready var sight_bubble = $SightBubble
@onready var hit_box = $HitBox
@onready var shadow = $Shadow

var state_machine = Node
var state_version: int = 0
var ENEMY_AI = Node

var coin_weight

# =========================================
# EXPORTS
# =========================================

@export_group("sfx")
@export var hurt_sfx: Resource
@export var hit_sfx: Resource

@export_group("basic")
@export var dumb: bool = false
@export var friendly: bool = false
@export var flying: bool = false
@export var weapon_user = true
@export var will_throw = false
@export var max_health: float = 100
@export var basic_damage: float = 5
@export var damage_factor: float = 1.0
@export var sight_radius: float = 216

@export_group("combat")
@export var lose_time: float = 1
@export var original_attack_range: int = 50
var attack_range: int = original_attack_range
@export var attack_hits: int = 2

# AI state request — set by enemy_ai.gd, read by update_ai_request()
enum Ai_State_Request { attack, block, idle, jump, roll, run, throw, empty, fall }
var ai_state: Ai_State_Request = Ai_State_Request.idle

# =========================================
# COMBAT VARIABLES
# =========================================

@export var item: Resource
@export var weapon_hand_offset: Vector2 = Vector2(0, 0)
@export var follow_up: bool
@export var patrol_range: float = 100
var found_weapon  # FLAG: worth typing as Node2D or WeaponPickup when possible
@export var attack_thrust_factor: float = 1.0
@export var knockback_factor: float = 1.0
var knocked_back: bool
var knockback_force: float
@export var knockback_recovery: float = 0.35
var recovery_timer: float = 0.0
var weapon: WeaponItem = null
var throw_path: String
var animations: Array[String]
var has_weapon: bool = false
var parry: bool = false
var combo_count: = 4
var combo_counter: int = 0
var combo_cooldown: float = 0.7
var combo_cooldown_timer: float = 0.0
var combo_reset_timer: float = 0.0
var pickup_reset_timer: float = 0.0
@export var combo_reset_time: float = 0.5
var original_combo_reset: float = combo_reset_timer  # FLAG: this will always be 0.0 at declaration time, set in _ready instead
var is_throw: bool = false

# =========================================
# MOVEMENT VARIABLES
# =========================================

# Cached at ready so raycasts can be reset after being aimed each frame
@onready var original_feet_target_position = feet_cast.target_position
@onready var original_plat_target_position = platform_cast.target_position

@export_group("movement")
@export var acceleration = 100
var direction: int = 1
var direction_y: int = 0
var sprint = false
var friction = 20
@export var max_speed = 100
@onready var prev_speed = max_speed
@export var jump_strength = -250
@export var roll_distance = 30
var coyote_time = 0.2   # seconds the enemy can still jump after walking off a ledge
var coyote_timer = 0.0
var in_air = false
var flip_h = false
@export var can_air_roll = true
var has_air_rolled = false
@export var can_double_jump = true
var has_double_jumped = false
@export var can_air_throw = true

var dead = false
var basic_attack: bool = true
var health: float

# =========================================
# SIGNALS
# =========================================

signal attacked
signal died(enemy)

# =========================================
# READY
# =========================================

func _ready() -> void:
	z_index = 0
	y_sort_enabled = true
	var bubble_coll = $SightBubble/bubble_collision
	health = max_health
	bubble_coll.shape.radius = sight_radius
	state_machine = $StateMachine
	ENEMY_AI = $EnemyAi
	state_machine.init(player_ref)
	ENEMY_AI.init(player_ref)
	if item != null:
		equip_weapon(item, WeaponPickup.new())
	hit_box.coll.disabled = true
	connect("attacked", on_attacked)
	connect("died", on_died)
	
	#Setup flying enemies raycast
	if flying:
		feet_cast.position = Vector2.ZERO
		feet_cast.target_position = Vector2(0, 15)
	

# =========================================
# PHYSICS PROCESS
# =========================================

func _physics_process(delta: float) -> void:
	# Virtual — subclasses can inject logic here without overriding _physics_process
	secondary_process()
	

	# Switch between basic and weapon-based attack pattern
	if weapon == null:
		basic_attack = true
		combo_reset_time = 0.5
	elif weapon_user:
		basic_attack = false
		combo_reset_time = original_combo_reset

	debug.text = (str(ENEMY_AI.state))

	# Death check
	if health <= 0 and !dead:
		die()

	# Run AI and animation — AI is skipped during hurt state
	if state_machine.current_state.get_state_name() != "HurtState":
		ENEMY_AI.control_process(delta)
		update_ai_request()
	update_animations()

	# Direction from flip
	if flip_h:
		direction = -1
	else:
		direction = 1
	animation.flip_h = flip_h

	# Gravity and coyote time
	if not is_on_floor() and !flying:
		if not coyote_timer > 0 and in_air == false:
			coyote_timer = coyote_time
			in_air = true
		velocity.y += Game.GRAVITY * delta
		if !flying and velocity.y > 100 and not animation.animation.contains("attack") and not state_machine.current_state.get_state_name() == "HurtState":
			if !dead: state_machine.change_state("FallState")
	elif !flying:
		in_air = false
		has_air_rolled = false
		has_double_jumped = false
	if coyote_timer > 0:
		coyote_timer -= 1 * delta

	# Tick all combat timers
	if pickup_reset_timer > 0.0:
		pickup_reset_timer -= delta * 1
	if combo_cooldown_timer > 0.0:
		combo_cooldown_timer -= delta * 1
	if combo_reset_timer > 0.0:
		combo_reset_timer -= delta * 1
	if recovery_timer > 0.0:
		recovery_timer -= delta * 1

	# Flying enemies animate float
	if flying:
		Game.animate_floating(animation)
		if feet_cast.get_collider() != null:
			if feet_cast.is_colliding() and feet_cast.get_collider().is_in_group("enviroment"):
				global_position.y -= 50 *delta

	# Apply state machine input and clamp velocity outside of override states
	state_machine.current_state.update_input()
	var current = state_machine.current_state.get_state_name()
	if not current == "AttackState" and not current == "RollState" and not current == "HurtState":
		velocity.x = clamp(velocity.x, -max_speed, max_speed)
	move_and_slide()

# =========================================
# ATTACK PATTERN
# =========================================

func set_attack_pattern(combo: int, anim: Array[String]):
	combo_count = combo
	animations = anim

# =========================================
# AI REQUEST HANDLER
# Reads ai_state set by enemy_ai.gd and translates it into state machine changes
# =========================================

func update_ai_request() -> void:
	var current = state_machine.current_state.get_state_name()
	if dead or current == "HurtState":
		return

	if current != "HurtState" and current != "AttackState":
		if ai_state == Ai_State_Request.attack:
			state_machine.change_state("AttackState")
		if ai_state == Ai_State_Request.throw:
			# FLAG: no throw_timer check here — if you want throw cooldown enforced
			# check ENEMY_AI.throw_timer <= 0 before changing state
			if weapon and weapon.throwable: state_machine.change_state("ThrowState")
		if ai_state == Ai_State_Request.idle:
			state_machine.change_state("IdleState")
		if ai_state == Ai_State_Request.run:
			state_machine.change_state("RunState")
		if (ai_state == Ai_State_Request.jump and (is_on_floor() or (can_double_jump and !has_double_jumped)) and !flying):
			state_machine.change_state("JumpState")
		if ai_state == Ai_State_Request.fall:
			_follow_down()

var follow_down: bool = false
func _follow_down():
	if !follow_down:
		follow_down = true
		if flying:
			feet_cast.enabled = false
			await Game.wait_for_seconds(0.1)
			feet_cast.enabled = true
		else:
			var ran = [1, -1].pick_random()
			if ran == 1:
				global_position.y += 3
				follow_down = false
			else:
				await Game.wait_for_seconds(randf_range(1, 2))
				follow_down = false
	

# =========================================
# ANIMATION
# =========================================

func update_animations() -> void:
	state_machine.current_state.update_animation()
	if weapon != null:
		weapon.sync_with_animation(animation.animation, animation.frame, flip_h)
	# Sprint speed modifier
	if sprint:
		max_speed = prev_speed * 1.3
	else:
		max_speed = prev_speed

# =========================================
# COMBAT
# =========================================

var knock_back_direction: Vector2

func take_damage(damage, from: Node2D, knockback: float = 10, auto_kill: bool = false):
	if !dead:
		if parry:
			from.parried(self)
			return
		health -= damage
		if auto_kill:
			health =0
		damage_particles()
		await get_knockback_direction(from)
		if state_machine.current_state.get_state_name() == "HurtState":
			state_machine.current_state.retrigger()
		else:
			state_machine.change_state("HurtState")
		if from == null:
			return
		knockback_force = 15 * knockback * knock_back_direction.x * knockback_factor

func get_knockback_direction(from):
	# Explosions knock directly away from source
	if from != null:
		if from.name == "Explosion":
			knock_back_direction.x = sign(global_position.x - from.global_position.x)
			return
	else:
		return
	# For everything else, derive direction from how the attacker moved this frame
	# FLAG: uses get_tree().process_frame directly — could cause issues if this node
	# is freed mid-await. Consider Game.wait_for_seconds(get_physics_process_delta_time())
	var pos1: Vector2
	var pos2: Vector2
	pos1 = from.global_position
	await get_tree().process_frame
	if from == null:
		return
	pos2 = from.global_position
	knock_back_direction = -sign(pos1 - pos2)
	await get_tree().process_frame

# =========================================
# DEATH
# =========================================

func die() -> void:
	if !dead:
		died.emit(self)
		dead = true
		dumb = true  # disables AI processing
		if weapon:
			disarm()
		if shadow: shadow.queue_free()
		state_machine.change_state("DieState")

# =========================================
# WEAPON EQUIP
# =========================================

var weapon_hit_box_reach_offset: Vector2
var pending_weapon_res: Resource = null
var pending_pickup_scene: RigidBody2D = null

func equip_weapon(res: Resource, pickup: RigidBody2D = null) -> void:
	if pickup == null:
		return
	pending_weapon_res = res
	pending_pickup_scene = pickup
	call_deferred("_do_equip")

func _do_equip() -> void:
	if (not pending_weapon_res) or (pending_pickup_scene == null):
		return
	weapon = WeaponItem.new()
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

func disarm():
	if weapon:
		pickup_reset_timer = 2
		var drop = WeaponPickup.new()
		drop.res = weapon.weapon
		if drop != null:
			get_parent().add_child(drop)
			drop.global_position = global_position
			drop.apply_impulse(Vector2(0, -10))
			drop.apply_torque(-direction * 10)
			has_weapon = false
			weapon.call_deferred("queue_free")

# =========================================
# VIRTUAL FUNCTIONS
# Override these in subclasses to extend enemy behavior without touching this script
# =========================================

func damage_particles() -> void:
	pass

func on_attacked() -> void:
	pass

func on_died(_enemy) -> void:
	pass

func secondary_process() -> void:
	pass
