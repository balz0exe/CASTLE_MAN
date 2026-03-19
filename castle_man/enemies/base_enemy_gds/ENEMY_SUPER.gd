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
@onready var sight_bubble = $SightBubble
@onready var hurt_box = $HurtBox
var state_machine = Node

@export var hurt_sfx: Resource

@export var max_health: float = 100
@export var dumb: bool = false
var basic_attack: bool = true
@export var weapon_user = true
var health = max_health

#WEAPON VARIABLES

@export var item: PackedScene
@export var damage_factor: float = 1.0
var found_weapon
var knocked_back: bool
var knockback_force: int
var knockback_recovery: float = 0.8
var recovery_timer: float = 0.0
var weapon: WeaponItem = null
var throw_path: String
var animations: Array[String]
var has_weapon: bool = false
var parry: bool = false
var combo_count: = 4
var combo_cooldown: float = 0.7
var combo_cooldown_timer: float = 0.0
var combo_reset_timer: float = 0.0
var is_throw: bool = false

#CONTROL VARIABLES

@export var attack_range: int
@export var attack_hits: int = 2
var dead = false
var control_state: String
var block: bool = false
var attack: bool = false
var hit_count: int
var dodge: bool = false
var jump: bool = false
var moving: bool = false
var is_sprinting: bool = false
var throw: bool = false
var patrolling: bool = false
var chasing: bool = false
var fighting: bool = false
var waiting: bool = false
var can_flip: bool = true
var flip_timer: float = 0.0
var flip_time: float = 0.2
var jump_timer: float = 0.0
var jump_time: float = 0.2
var can_jump: bool = true
var wind_up: bool = false
var enemy: Node2D

#SIGHT VARIABLES

@export var sight_radius: float = 216
var sight_is_searching: bool = false
var looking_for_weapon: bool = false

#MOVEMENT VARIABLES

@onready var original_target_position = feet_cast.target_position
@onready var original_feet_cast_position = feet_cast.position
@export var acceleration = 500
var direction: int = 1
var direction_y: int = 0
var sprint = false
var friction = 20
@export var max_speed = 200
var prev_speed = max_speed
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
	hurt_box.connect("body_entered", hurt_box_body_entered)
	state_machine.init(player_ref)
	if item != null:
		equip_weapon(item, null)

func control_process(delta) -> void:
	if dumb or dead:
		return
	#timers
	if flip_timer > 0:
		flip_timer -= 1 * delta
	else:
		can_flip = true
	if jump_timer > 0:
		jump_timer -= 1 * delta
	else:
		can_jump = true
	
	if waiting:
		return
	
	if enemy != null:
		if !enemy.dead:
			var distance = enemy.global_position.x - global_position.x
			if abs(distance) > attack_range + 20:
				chase(enemy)
			elif abs(distance) < attack_range - 20 and not waiting:
				fight(enemy)
		else:
			Game.wait_for_seconds(2)
			patrol(global_position.x)
	else:
		patrol(global_position.x)
		
	#casts direction
	wall_cast.target_position = Vector2(direction * 50, 0)
	feet_cast.target_position = Vector2(direction * original_target_position.x, original_target_position.y)
	feet_cast.position.x = direction * 10
	var colliders = sight_bubble.get_overlapping_bodies()
	var is_player = false
	var _body
	for body in colliders:
		if body.is_in_group("player"):
			is_player = true
			_body = body
	if is_player:
		sight_is_searching = true
		sight_cast.target_position = _body.global_position - global_position
		sight_cast.force_raycast_update()

		if sight_cast.is_colliding():
			var collider = sight_cast.get_collider()
			if collider and not collider.is_in_group("enviroment"):
				if enemy == null:
					_jump(0.2)
					if weapon_user and weapon == null and !looking_for_weapon:
						look_for_weapon()
					enemy = _body
	else:
		sight_is_searching = false
	
	#navigating
	var line_of_sight = wall_cast.get_collider()
	if line_of_sight != null:
		if line_of_sight.is_in_group("enviroment"):
			if chasing:
				var x = global_position.y
				await _jump(0.5)
				while !is_on_floor():
					await get_tree().process_frame
				var y = global_position.y
				if x == y:
					enemy = null
				
			else:
				_flip()

	var last_feet_collider
	if feet_cast.get_collider() != null:
		last_feet_collider = feet_cast.get_collider()
	if is_on_floor():
		if feet_cast.get_collider() == null:
			if chasing:
				patrol(global_position.x)
			else:
				_flip()
				
func update_control_state_switches(current_state: String):
	control_state = current_state
	match current_state:
		"patrol":
			patrolling = true
			chasing = false
			fighting = false
			waiting = false
		"chase":
			chasing = true
			patrolling = false
			fighting = false
			waiting = false
		"fight":
			fighting = true
			chasing = false
			patrolling = false
			waiting = false
		"wait":
			waiting = true
			fighting = false
			chasing = false
			patrolling = false

func wait():
	if waiting:
		return
	update_control_state_switches("wait")

func fight(target: Node2D) -> void:
	if fighting:
		return

	update_control_state_switches("fight")

	while fighting and is_instance_valid(target):
		var distance = abs(target.global_position.x - global_position.x)
		if distance > attack_range:
			if weapon_user and weapon == null:
				await look_for_weapon()
			await _move_towards(target, 0.2)
		else:
			if !basic_attack:
				_attack(attack_hits)
			else:
				await _attack(1)
			await attacked
			await Game.wait_for_seconds(0.2)
			await _move_towards_x(target.global_position.x + (direction * float(attack_range)/2), 0.3)
			await Game.wait_for_seconds(0.2)

signal done_looking_for_weapon

func look_for_weapon() -> void:
	if looking_for_weapon:
		return
	found_weapon = null
	looking_for_weapon = true
	var bodies = sight_bubble.get_overlapping_bodies()
	print(str(bodies))
	for body in bodies:
		if body.is_in_group("weapons"):
			found_weapon = body
			wait()
	while weapon == null and found_weapon != null:
		_move_towards_x(found_weapon.global_position.x)
		await moved
		await get_tree().process_frame
	chase(enemy)
	done_looking_for_weapon.emit()
	Game.wait_for_seconds(0.5)
	looking_for_weapon = false

func patrol(start: float, _range: float = 100) -> void:
	if patrolling:
		return
	update_control_state_switches("patrol")
	while patrolling:
		if abs(start - global_position.x) > _range:
			await _move_towards_x(start, 1)
		await Game.wait_for_seconds(randi() %5 + 1)
		await _move_to_x(start + _range * randf_range(-1, 1))
	
func chase(target: Node2D) -> void:
	if chasing:
		return
	update_control_state_switches("chase")
	while chasing:
		await _move_towards(target, 0.2)
		if target == null:
			patrol(global_position.x)

#CONTROL FUNCTIONS

signal threw
func _throw() -> void:
	animation.play("wind_up")
	await animation.animation_finished
	throw = true
	await Game.wait_for_seconds(0.2)
	throw = false
	await Game.wait_for_seconds(0.5)
	threw.emit()

signal dodged
func _dodge() -> void:
	dodge = true
	await Game.wait_for_seconds(0.2)
	dodge = false
	await Game.wait_for_seconds(0.5)
	dodged.emit()

signal jumped
func _jump(time: float = 0.01) -> void:
	if !can_jump:
		return
	can_jump = false
	jump = true
	await Game.wait_for_seconds(time)
	jump = false
	await Game.wait_for_seconds(0.5)
	jumped.emit()

func _face_towards(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	
	# Determine the direction to face
	if target.global_position.x > global_position.x:
		flip_h = false
		direction = 1
	else:
		flip_h = true
		direction = -1

signal moved
func _move(time: float = 0.1, _sprint: bool = false) -> void:
	moving = true
	is_sprinting = _sprint
	await Game.wait_for_seconds(time)
	moving = false
	is_sprinting = false
	await Game.wait_for_seconds(0.1)
	moved.emit()

func _move_to_x (target: float, _sprint: bool = false) -> void:
	var distance_to_target = global_position.x - target
	if (distance_to_target > 0 and direction == 1) or (distance_to_target < 0 and direction == -1):
		_flip()
	moving = true
	is_sprinting = _sprint
	while abs(global_position.x - target) > 20:
		await get_tree().process_frame
	moving = false
	is_sprinting = false
	moved.emit()

func _move_towards_x(target: float, time: float = 0.1, _sprint: bool = false) -> void:
	var distance_to_target = global_position.x - target
	if (distance_to_target > 0 and direction == 1) or (distance_to_target < 0 and direction == -1):
		_flip()
	moving = true
	is_sprinting = _sprint
	await Game.wait_for_seconds(time)
	moving = false
	is_sprinting = false
	moved.emit()

func _move_towards(target: Node2D, time: float = 0.1, _sprint: bool = false) -> void:
	if target != null:
		var distance_to_target = global_position - target.global_position
		if (distance_to_target.x > 0 and direction == 1) or (distance_to_target.x < 0 and direction == -1):
			_flip()
		moving = true
		is_sprinting = _sprint
		await Game.wait_for_seconds(time)
		moving = false
		is_sprinting = false
		moved.emit()

func _flip() -> void:
	if !can_flip:
		return
	flip_timer = flip_time
	if can_flip: flip_h = !flip_h
	can_flip = false

signal attacked
func _attack(hits: int) -> void:
	if enemy:
		_face_towards(enemy)
		hit_count = hits
		attack = true
		await Game.wait_for_seconds(0.2)
		attack = false

func _physics_process(delta: float) -> void:
	#debug

	if weapon == null:
		basic_attack = true
	elif weapon_user:
		basic_attack = false

	debug.text = str(control_state)

	if health <= 0 and !dead:
		die()
	#update animation and control script

	update_animations()
	control_process(delta)
	
	
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

	if block:
		if !dead: state_machine.change_state("BlockState")
	if has_weapon:
		if throw:
			if !dead: state_machine.change_state("ThrowState")

	if combo_cooldown_timer > 0.0:
		combo_cooldown_timer -= delta * 1
	if combo_reset_timer > 0.0:
		combo_reset_timer -= delta * 1
	
	#update state inputs
	state_machine.current_state.update_input()
	if not state_machine.current_state.get_state_name() == "RollState": velocity.x = clamp(velocity.x, -max_speed, max_speed)
	
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
		max_speed = prev_speed * 2
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
	while state_machine.current_state.get_state_name() == "HurtState":
		await get_tree().process_frame

func hurt_box_body_entered(body) -> void:
	if body.is_in_group("player") and !body.dead:
		if weapon != null: body.take_damage(weapon.damage * damage_factor, self)
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
	state_machine.change_state("DieState")

var pending_weapon_scene
var pending_pickup_scene

func equip_weapon(weapon_scene: PackedScene, pickup_scene: RigidBody2D):
	# Just store the latest request
	pending_weapon_scene = weapon_scene
	if pickup_scene: pending_pickup_scene = pickup_scene
	# Schedule the actual equip for the end of the frame
	call_deferred("_do_equip")

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
