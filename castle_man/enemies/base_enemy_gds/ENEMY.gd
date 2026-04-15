#enemy.gd
extends CharacterBody2D
class_name Enemy

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
var state_version : int = 0
var ENEMY_AI = Node

@export var hurt_sfx: Resource
@export var hit_sfx: Resource

@export var dumb: bool = false
@export var weapon_user = true
@export var will_throw = false

@export var max_health: float = 100
@export var basic_damage: float = 5
@export var damage_factor: float = 1.0

#ENEMY.AI

@export var lose_time: float = 1
@export var original_attack_range: int = 50
var attack_range: int = original_attack_range
@export var attack_hits: int = 2
@export var sight_radius: float = 216

enum Ai_State_Request {attack, block, idle, jump, roll, run, throw, empty}
var ai_state : Ai_State_Request = Ai_State_Request.idle

#COMBAT VARIABLES

@export var item: Resource
@export var weapon_hand_offset: Vector2 = Vector2(0,0)
@export var follow_up: bool
@export var patrol_range: float = 100
var found_weapon
@export var attack_thrust_factor : float = 1.0
@export var knockback_factor: float = 1.0
var knocked_back: bool
var knockback_force: int
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
var original_combo_reset: float = combo_reset_timer
var is_throw: bool = false

#MOVEMENT VARIABLES

@onready var original_feet_target_position = feet_cast.target_position
@onready var original_plat_target_position = platform_cast.target_position
@export var acceleration = 100
var direction: int = 1
var direction_y: int = 0
var sprint = false
var friction = 20
@export var max_speed = 100
@onready var prev_speed = max_speed
@export var jump_strength = -250
@export var roll_distance = 30
var coyote_time = 0.2
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
var health : float

signal attacked
signal died

func _ready() -> void:
	z_index = 1
	var bubble_coll = $SightBubble/bubble_collision
	health = max_health
	bubble_coll.shape.radius = sight_radius
	state_machine = $StateMachine
	ENEMY_AI = $EnemyAi
	state_machine.init(player_ref)
	ENEMY_AI.init(player_ref)
	if item != null:
		equip_weapon(item, null)
	
	connect("attacked", on_attacked)
	connect("died", on_died)

func _physics_process(delta: float) -> void:
	
	secondary_process()
	
	if weapon == null:
		basic_attack = true
		combo_reset_time = 0.5
	elif weapon_user:
		basic_attack = false
		combo_reset_time = original_combo_reset

	debug.text = (str(health))

	if health <= 0 and !dead:
		die()

	#update animation and Ai script
	
	if state_machine.current_state.get_state_name() != "HurtState":
		ENEMY_AI.control_process(delta)
		update_ai_request()
	update_animations()
	
	#check direction

	if flip_h:
		direction = -1
	else:
		direction = 1

	animation.flip_h = flip_h
	
	#gravity and air roll

	if not is_on_floor():
		if not coyote_timer > 0 and in_air == false:
			coyote_timer = coyote_time
			in_air = true
		velocity.y += Game.GRAVITY * delta
		if velocity.y > 100 and not animation.animation.contains("attack") and not state_machine.current_state.get_state_name() == "HurtState":
			if !dead: state_machine.change_state("FallState")
	else:
		in_air = false
		has_air_rolled = false
		has_double_jumped = false
	if coyote_timer > 0:
		coyote_timer -= 1 * delta


	#attack timers

	if pickup_reset_timer > 0.0:
		pickup_reset_timer -= delta * 1
	if combo_cooldown_timer > 0.0:
		combo_cooldown_timer -= delta * 1
	if combo_reset_timer > 0.0:
		combo_reset_timer -= delta * 1
	if recovery_timer > 0.0:
		recovery_timer -= delta * 1
	
	#update state inputs
	state_machine.current_state.update_input()
	var current = state_machine.current_state.get_state_name()
	if not current == "AttackState" and not current == "RollState" and not current == "HurtState":
		velocity.x = clamp(velocity.x, -max_speed, max_speed)

	move_and_slide()
	
func set_attack_pattern(combo: int, anim: Array[String]):
	combo_count = combo
	animations = anim

func update_ai_request() -> void:
	var current = state_machine.current_state.get_state_name()
	if dead or current == "HurtState":
		return
	
	if current != "HurtState" and current != "AttackState":
		if ai_state == Ai_State_Request.attack:
			state_machine.change_state("AttackState")
		if ai_state == Ai_State_Request.throw:
			if weapon and weapon.throwable: state_machine.change_state("ThrowState")
		if ai_state == Ai_State_Request.idle:
			state_machine.change_state("IdleState")
		if ai_state == Ai_State_Request.run:
			state_machine.change_state("RunState")
		if ai_state == Ai_State_Request.jump and (is_on_floor() or (can_double_jump and !has_double_jumped)):
			state_machine.change_state("JumpState")

func update_animations() -> void:
	state_machine.current_state.update_animation()
	if weapon != null:
		weapon.sync_with_animation(animation.animation, animation.frame, flip_h)
	if sprint:
		max_speed = prev_speed * 1.3
	else:
		max_speed = prev_speed
	
var knock_back_direction
func take_damage(damage, from: Node2D, knockback: float = 10):
	if !dead:
		if parry:
			from.parried(self)
			return
		health = health - damage
		damage_particles()
		await get_knockback_direction(from)
		knockback_force = 15 * knockback * knock_back_direction.x * knockback_factor
		if state_machine.current_state.get_state_name() == "HurtState":
			state_machine.current_state.retrigger()
		else:
			state_machine.change_state("HurtState")
			
func get_knockback_direction(from):
	var pos1: Vector2
	var pos2: Vector2
	pos1 = from.global_position
	await get_tree().process_frame
	pos2 = from.global_position
	knock_back_direction = -sign(pos1 - pos2)
	await get_tree().process_frame

func die() -> void:
	dead = true
	dumb = true
	if weapon:
		disarm()
	shadow.queue_free()
	state_machine.change_state("DieState")

var pending_weapon_res: Resource = null
var pending_pickup_scene: RigidBody2D = null

func equip_weapon(res: Resource, pickup: RigidBody2D):
	# Just store the latest request
	pending_weapon_res = res
	pending_pickup_scene = pickup
	# Schedule the actual equip for the end of the frame
	call_deferred("_do_equip")

var weapon_hit_box_reach_offset: Vector2

func _do_equip():
	if not pending_weapon_res:
		return
		
	weapon = WeaponItem.new()
	if pending_pickup_scene: pending_pickup_scene.queue_free()
	# ... rest of your setup ...
	
	# Clear the pending status so it doesn't run again unless called
	has_weapon = true
	hit_box.get_child(0).shape = pending_weapon_res.hurt_box_shape
	weapon_hit_box_reach_offset = pending_weapon_res.hurt_box_offset
	weapon.set_meta("resource_path", pending_weapon_res.resource_path)
	pending_pickup_scene = null
	weapon.owner_player = self
	weapon_hand.add_child(weapon)
	weapon.on_equip(self, pending_weapon_res)
	pending_weapon_res = null

func disarm():
	if weapon:
		var drop = WeaponPickup.new()
		await get_tree().process_frame
		if drop != null:
			get_parent().add_child(drop)
			drop.global_position = global_position
			drop.apply_impulse(Vector2(0, -10))
			drop.apply_torque(-direction * 10)
			has_weapon = false
			weapon.call_deferred("queue_free")

#EMPTY FUNCTIONS

func damage_particles() -> void:
	pass

func on_attacked() -> void:
	pass

func on_died() -> void:
	pass
	
func secondary_process() -> void:
	pass
