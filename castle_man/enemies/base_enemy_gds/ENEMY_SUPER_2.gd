#enemy.gd
extends CharacterBody2D
#class_name Enemy

@onready var animation = $AnimatedSprite2D
@onready var hit_box = $CollisionShape2D
@onready var debug = $debug
@onready var player_ref = self
@onready var weapon_hand = $weapon_hand
@onready var sight_cast = $SightCast
@onready var wall_cast = $WallCast
@onready var feet_cast = $FeetCast
@onready var platform_cast = $PlatformCast
@onready var sight_bubble = $SightBubble
@onready var hurt_box = $HurtBox
@onready var shadow = $Shadow
var state_machine = Node
var state_version : int = 0
var ENEMY_AI = Node

@export var hurt_sfx: Resource
@export var hit_sfx: Resource

@export var max_health: float = 100
var dead = false
@export var dumb: bool = false
var basic_attack: bool = true
@export var weapon_user = true
var health = max_health

#WEAPON VARIABLES

@export var item: PackedScene
@export var damage_factor: float = 1.0
@export var follow_up: bool
@export var patrol_range: float = 100
var found_weapon
@export var attack_thrust_factor : float = 1.0
var knocked_back: bool
var knockback_force: int
@export var knockback_recovery: float = 1
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
var is_throw: bool = false

#ENEMY.AI

@export var attack_range: int = 50
@export var attack_hits: int = 2
@export var sight_radius: float = 216

#MOVEMENT VARIABLES

@onready var original_target_position = feet_cast.target_position
@onready var original_feet_cast_position = feet_cast.position
@export var acceleration = 100
var direction: int = 1
var direction_y: int = 0
var sprint = false
var friction = 20
@export var max_speed = 100
@onready var prev_speed = max_speed
@export var jump_strength = -300
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

func _ready() -> void:
	var bubble_coll = $SightBubble/bubble_collision
	bubble_coll.shape.radius = sight_radius
	state_machine = $StateMachine
	ENEMY_AI = $EnemyAi
	hurt_box.connect("body_entered", hurt_box_body_entered)
	state_machine.init(player_ref)
	ENEMY_AI.init(player_ref)
	if item != null:
		equip_weapon(item, null)

func _physics_process(delta: float) -> void:

	if weapon == null:
		basic_attack = true
	elif weapon_user:
		basic_attack = false

	debug.text = ("target:" + str(ENEMY_AI.state))

	if health <= 0 and !dead:
		die()

	#update animation and control script

	update_animations()
	ENEMY_AI.control_process(delta)
	
	#check direction

	if flip_h:
		direction = -1
	else:
		direction = 1
	
	#hurt box collisions
	if animation.animation.contains("attack") and animation.frame == 1:
		velocity.x += direction * 30
		hurt_box.monitoring = true
	else:
		if animation.animation.contains("attack") and animation.frame == 0: velocity.x = 0
		hurt_box.monitoring = false
	
	#gravity and air roll

	if not is_on_floor():
		if not coyote_timer > 0 and in_air == false:
			coyote_timer = coyote_time
			in_air = true
		velocity.y += Game.GRAVITY * delta
		if velocity.y > 50 and not animation.animation.contains("attack") and not state_machine.current_state.get_state_name() == "HurtState":
			if !dead: state_machine.change_state("FallState")
	else:
		in_air = false
		has_air_rolled = false
		has_double_jumped = false
	if coyote_timer > 0:
		coyote_timer -= 1 * delta


	#attack timers

	if ENEMY_AI.block:
		if !dead: state_machine.change_state("BlockState")
	if has_weapon:
		if ENEMY_AI.throw:
			if !dead: state_machine.change_state("ThrowState")

	if combo_cooldown_timer > 0.0:
		combo_cooldown_timer -= delta * 1
	if combo_reset_timer > 0.0:
		combo_reset_timer -= delta * 1
	
	#update state inputs
	state_machine.current_state.update_input()
	if not state_machine.current_state.get_state_name() == "AttackState" or not state_machine.current_state.get_state_name() == "RollState":
		velocity.x = clamp(velocity.x, -max_speed, max_speed)
	
	move_and_slide()
	
func set_attack_pattern(combo: int, anim: Array[String]):
	combo_count = combo
	animations = anim
	
func update_animations() -> void:
	state_machine.current_state.update_animation()
	if animation.animation == "attack up" or animation.animation == "attack down":
		animation.flip_h = !flip_h
	else:
		animation.flip_h = flip_h
	if weapon != null:
		weapon.sync_with_animation(animation.animation, animation.frame, flip_h)
	if sprint:
		max_speed = prev_speed * 1.3
	else:
		max_speed = prev_speed
	
func take_damage(damage, from: Node2D, knockback: float = 10):
	if dead:
		return
	
	knockback_recovery = 0.1
	if parry:
		from.parried(self)
		return
	health = health - damage
	var knock_back_direction = -sign(from.global_position.x - global_position.x)
	knockback_force = 20 * knockback * knock_back_direction
	state_machine.change_state("HurtState")
	
func parried(from: Node2D, knockback: float = 3):
	velocity.y -= 30
	velocity.x = 0
	knockback_recovery = 0.8
	var knock_back_direction = -sign(from.global_position.x - global_position.x)
	knockback_force = 10 * knockback * knock_back_direction
	state_machine.change_state("HurtState")

func hurt_box_body_entered(body) -> void:
	if body.is_in_group("player") and !body.dead:
		if weapon != null: body.take_damage(weapon.damage * damage_factor, self, weapon.knockback)
		else: body.take_damage(damage_factor, self)

func die() -> void:
	dead = true
	dumb = true
	var drop
	if weapon:
		drop = load(weapon.throw_path)
	if drop != null:
		drop = drop.instantiate()
		drop.global_position = global_position
		drop.apply_impulse(Vector2(0, -10))
		drop.apply_torque(-direction * 10)
		get_parent().add_child(drop)
	shadow.queue_free()
	state_machine.change_state("DieState")

var pending_weapon_scene
var pending_pickup_scene

func equip_weapon(weapon_scene: PackedScene, pickup_scene: RigidBody2D):
	# Just store the latest request
	pending_weapon_scene = weapon_scene
	if pickup_scene: pending_pickup_scene = pickup_scene
	# Schedule the actual equip for the end of the frame
	call_deferred("_do_equip")

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
			weapon.queue_free()

var weapon_hurt_box_reach_offset: int

func _do_equip():
	if not pending_weapon_scene:
		return
		
	weapon = pending_weapon_scene.instantiate()
	if pending_pickup_scene: pending_pickup_scene.queue_free()
	# ... rest of your setup ...
	
	# Clear the pending status so it doesn't run again unless called
	has_weapon = true
	hurt_box.get_child(0).shape = weapon.get_child(0).shape
	weapon_hurt_box_reach_offset = weapon.get_child(0).position.x
	weapon.set_meta("resource_path", pending_weapon_scene.resource_path)
	pending_weapon_scene = null
	pending_pickup_scene = null
	weapon.owner_player = self
	weapon_hand.add_child(weapon)
	weapon.on_equip(self)
