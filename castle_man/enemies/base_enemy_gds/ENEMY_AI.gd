#enemy_ai.gd
extends Node

#CONTROL VARIABLES

enum State { WAIT, PATROL, CHASE, FIGHT, SEARCH_WEAPON }
var state : State = State.WAIT
var previous_state: State

# One-time state triggers
var state_entered_flag: bool = false
var state_exited_flag: bool = false

var state_version : int = 1

var control_state: String
var is_sprinting: bool = false
var can_flip: bool = true
var flip_timer: float = 0.0
var flip_time: float = 0.2
var jump_timer: float = 0.0
var jump_time: float = 0.2
var can_jump: bool = true
var wind_up: bool = false
var enemy: Node2D

#SIGHT VARIABLES

var sight_is_searching: bool = false
var looking_for_weapon: bool = false

var player: CharacterBody2D
var patrol_origin: float

func init(player_ref) -> void:
	player = player_ref
	patrol_origin = player.global_position.x
	if !player.dumb: set_state(State.PATROL)

# --- STATE MANAGEMENT ---

var ran_patrol_x : float

func set_state(new_state: State) -> void:
	if state == new_state or looking_for_weapon:
		return

	state_version += 1
	if player.state_machine.monitor:print("enemy changed ai too: " + str(new_state))
	previous_state = state
	state = new_state

	state_exited()
	state_entered()

func state_entered() -> void:
	state_entered_flag = true
	match state:
		State.WAIT:
			while await Game.wait_for_seconds(randi_range(2, 5)):
				if state != State.WAIT:
					return
			set_state(State.PATROL)
		State.PATROL:
			ran_patrol_x = patrol_origin + randf_range(-player.patrol_range, player.patrol_range)
		State.CHASE:
			pass
		State.FIGHT:
			player.ai_state = player.Ai_State_Request.attack
		State.SEARCH_WEAPON:
			looking_for_weapon = true
			var bodies = player.sight_bubble.get_overlapping_bodies()
			for body in bodies:
				if body.is_in_group("weapons"):
					player.found_weapon = body
			while player.weapon == null and player.found_weapon != null:
				_move_towards_x(player.found_weapon.global_position.x)
				await get_tree().process_frame
			looking_for_weapon = false
			set_state(State.CHASE)

func state_exited() -> void:
	state_exited_flag = true
	match previous_state:
		State.WAIT:
			pass
		State.PATROL:
			pass
		State.CHASE:
			pass
		State.FIGHT:
			pass
		State.SEARCH_WEAPON:
			done_looking_for_weapon.emit()
			player.found_weapon = null

func _physics_process(_delta: float) -> void:
	if player.state_machine.current_state.get_state_name() != "HurtState":
		match state:
			State.WAIT:
				player.ai_state = player.Ai_State_Request.idle

			State.PATROL:
				# Check distance to target
				var distance = ran_patrol_x - player.global_position.x

				# Start moving
				_move_towards_x(ran_patrol_x)

				# Pick new target if reached
				if abs(distance) < 5:
					ran_patrol_x = patrol_origin + randf_range(-player.patrol_range, player.patrol_range)
					set_state(State.WAIT)

			State.CHASE:
				if enemy != null and player.state_machine.current_state.get_state_name() != "HurtState":
					_move_towards_x(enemy.global_position.x, true)
				elif enemy == null:
					set_state(State.PATROL)

			State.FIGHT:
				if !is_instance_valid(enemy):
					set_state(State.PATROL)
				if player.combo_reset_timer > 0:
					if enemy: _move_towards_x(enemy.global_position.x + player.attack_range * player.direction, true)
			State.SEARCH_WEAPON:
				pass

signal done_looking_for_weapon

#==== PROCESS ====

func control_process(delta) -> void:
	if player.dumb or player.dead or player.state_machine.current_state.get_state_name() == "HurtState":
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
	
	if enemy != null:
		if !enemy.dead:
			var distance = enemy.global_position.x - player.global_position.x
			if abs(distance) > player.attack_range + 20:
				if state != State.WAIT: set_state(State.CHASE)
			elif abs(distance) < player.attack_range - 20 and not state == State.WAIT:
				if state != State.WAIT: set_state(State.FIGHT)
		else:
			lose_enemy(player.lose_time)
			if state != State.WAIT: set_state(State.PATROL)
	else:
		if state != State.WAIT: set_state(State.PATROL)
		

	navigate()

func navigate() -> void:
	
	#casts direction
	
	player.wall_cast.target_position = Vector2(player.direction * 50, 0)
	player.feet_cast.target_position = Vector2(player.direction * player.original_feet_target_position.x, player.original_feet_target_position.y)
	player.feet_cast.position.x = player.direction * 10
	player.platform_cast.target_position = Vector2(player.direction * player.original_plat_target_position.x, player.original_plat_target_position.y)
	player.platform_cast.position.x = player.direction * 10

	#navigating

	var colliders = player.sight_bubble.get_overlapping_bodies()
	var is_player = false
	var _body
	for body in colliders:
		if body.is_in_group("player"):
			is_player = true
			_body = body
	if is_player:
		sight_is_searching = true
		player.sight_cast.target_position = _body.global_position - player.global_position
		player.sight_cast.force_raycast_update()

		if player.sight_cast.is_colliding():
			var collider = player.sight_cast.get_collider()
			if collider and not collider.is_in_group("enviroment"):
				if enemy == null:
					if player.weapon_user and player.weapon == null and !looking_for_weapon:
						set_state(State.SEARCH_WEAPON)
					else:
						set_state(State.PATROL)
					enemy = _body
			else:
				lose_enemy(player.lose_time)
		else:
			lose_enemy(player.lose_time)
	else:
		sight_is_searching = false

	var line_of_sight = player.wall_cast.get_collider()
	if line_of_sight != null and enemy == null:
		if line_of_sight.is_in_group("enviroment"):
			_flip()
	if ((enemy != null and ((player.global_position.y - enemy.global_position.y) > 10 and enemy.is_on_floor()))) or state == State.SEARCH_WEAPON:
		if player.follow_up:
			if (state == State.CHASE or state == State.SEARCH_WEAPON) and player.platform_cast.is_colliding():
					if player.platform_cast.get_collider().is_in_group("enviroment"):
						var x = player.global_position.x
						print("!!!")
						player.ai_state = player.Ai_State_Request.jump
						player.update_ai_request()
						while player.is_on_floor():
							await get_tree().process_frame
						while !player.is_on_floor():
							await get_tree().process_frame
						var y = player.global_position.x
						if x == y:
							lose_enemy(player.lose_time)

	var _last_feet_collider
	if player.feet_cast.get_collider() != null:
		_last_feet_collider = player.feet_cast.get_collider()
	if player.is_on_floor():
		if player.feet_cast.get_collider() == null:
			if state == State.PATROL:
				_flip()

#CONTROL FUNCTIONS

func _face_towards(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	
	# Determine the direction to face
	if target.global_position.x > player.global_position.x:
		player.flip_h = false
		player.direction = 1
	else:
		player.flip_h = true
		player.direction = -1

signal moved
func _move_towards_x(target: float, _sprint: bool = false) -> void:
	var current_state = player.state_machine.current_state.get_state_name()
	if current_state == "HurtState":
		return
	var distance_to_target = target - player.global_position.x
	# Flip if needed
	if distance_to_target > 0 and player.direction == -1:
		_flip()
	elif distance_to_target < 0 and player.direction == 1:
		_flip()
	# Start moving toward target
	if player.state_machine.current_state.get_state_name() != "HurtState": player.ai_state = player.Ai_State_Request.run
	is_sprinting = _sprint
	# Already at target
	if current_state == "RunState" and !can_flip:
		distance_to_target = target - player.global_position.x
		if abs(distance_to_target) < 10 or (!player.feet_cast.is_colliding() and state == State.PATROL):
			moved.emit()
			is_sprinting = false
			return

func lose_enemy(time: float):
	await Game.wait_for_seconds(time)
	patrol_origin = player.global_position.x
	enemy = null

func _flip() -> void:
	if !can_flip:
		return
	if state == State.PATROL:
		ran_patrol_x = patrol_origin
	flip_timer = flip_time
	if can_flip: player.flip_h = !player.flip_h
	can_flip = false
