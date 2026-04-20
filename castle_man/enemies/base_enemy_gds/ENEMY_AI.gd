# enemy_ai.gd
# Handles all AI decision-making and navigation for enemies.
# Attached as a child node to each Enemy instance.
extends Node

# =========================================
# ENUMS & STATE
# =========================================

enum State { WAIT, PATROL, CHASE, FIGHT, SEARCH_WEAPON }
var state: State = State.WAIT
var previous_state: State

# Incremented on every state change — used to cancel stale async operations
var state_version: int = 1

# =========================================
# CONTROL FLAGS & TIMERS
# =========================================

var is_sprinting: bool = false

var can_flip: bool = true
var flip_timer: float = 0.0
var flip_time: float = 0.2

var can_jump: bool = true
var jump_timer: float = 0.0
var jump_time: float = 0.2

var wind_up: bool = false
var throw_timer: float = 0.0

# =========================================
# REFERENCES
# =========================================

var enemy: Node2D        # The target the AI is pursuing
var player: Enemy        # The enemy this AI controls (confusingly named — this is the AI's own body)
var patrol_origin: float # X position the enemy patrols around

# =========================================
# SIGHT / SEARCH
# =========================================

var sight_is_searching: bool = false
var looking_for_weapon: bool = false

# =========================================
# INIT
# =========================================

func init(player_ref) -> void:
	player = player_ref
	patrol_origin = player.global_position.x
	if !player.dumb:
		set_state(State.PATROL)

# =========================================
# STATE MANAGEMENT
# =========================================

var ran_patrol_x: float = 0.0
var has_attacked: bool = false
var searched_timer: float = 0.0
var search_cooldown: float = 1.0

func set_state(new_state: State) -> void:
	# Don't switch to the same state, and don't interrupt a weapon search
	if state == new_state or looking_for_weapon:
		return

	state_version += 1
	if player.state_machine.monitor:
		print("enemy changed ai to: " + str(new_state))

	previous_state = state
	state = new_state

	state_exited()
	state_entered()

func state_entered() -> void:
	match state:

		State.WAIT:
			# Wait a random amount of time then go back to patrolling
			while await Game.wait_for_seconds(randi_range(2, 5)):
				if state != State.WAIT:
					return
			set_state(State.PATROL)

		State.PATROL:
			# Pick a random X destination within patrol range
			ran_patrol_x = patrol_origin + randf_range(-player.patrol_range, player.patrol_range)

		State.CHASE:
			# If this enemy uses weapons but doesn't have one, go look for one
			if player.weapon_user and !player.weapon and !player.found_weapon and searched_timer <= 0:
				set_state(State.SEARCH_WEAPON)

		State.FIGHT:
			if looking_for_weapon:
				set_state(State.SEARCH_WEAPON)
				return
			player.ai_state = player.Ai_State_Request.attack
			has_attacked = true

		State.SEARCH_WEAPON:
			searched_timer = search_cooldown
			looking_for_weapon = true

			# Find a nearby melee weapon on the ground
			var bodies = player.sight_bubble.get_overlapping_bodies()
			for body in bodies:
				if body.is_in_group("weapons") and !body.ranged:
					if abs(player.global_position.y - body.global_position.y) < 10:
						player.found_weapon = body

			# Walk toward the weapon until picked up
			while player.weapon == null and player.found_weapon != null:
				_move_towards_x(player.found_weapon.global_position.x)
				if player.global_position.x == player.found_weapon.global_position.x:
					break
				await Game.wait_for_seconds(get_physics_process_delta_time())

			looking_for_weapon = false
			set_state(State.CHASE)

func state_exited() -> void:
	match previous_state:

		State.FIGHT:
			has_attacked = false

		State.SEARCH_WEAPON:
			done_looking_for_weapon.emit()
			player.found_weapon = null

signal done_looking_for_weapon

# =========================================
# PHYSICS PROCESS
# =========================================

func _physics_process(delta: float) -> void:
	# Tick down cooldown timers
	if searched_timer > 0:
		searched_timer -= delta
	if throw_timer > 0:
		throw_timer -= delta

	# Don't run AI logic while being hurt
	if player.state_machine.current_state.get_state_name() == "HurtState":
		return

	match state:
		State.WAIT:
			player.ai_state = player.Ai_State_Request.idle

		State.PATROL:
			var distance = ran_patrol_x - player.global_position.x
			_move_towards_x(ran_patrol_x)
			# Pick a new patrol destination when we arrive
			if abs(distance) < 5:
				ran_patrol_x = patrol_origin + randf_range(-player.patrol_range, player.patrol_range)
				set_state(State.WAIT)

		State.CHASE:
			if enemy != null:
				_move_towards_x(enemy.global_position.x, true)
			else:
				set_state(State.PATROL)

		State.FIGHT:
			if !is_instance_valid(enemy):
				set_state(State.PATROL)
			_face_towards(enemy)

		State.SEARCH_WEAPON:
			# Weapon was picked up mid-search, resume chasing
			if player.weapon != null:
				set_state(State.CHASE)

# =========================================
# CONTROL PROCESS (called externally by the enemy)
# =========================================

func control_process(delta: float) -> void:
	if player.dumb or player.dead or player.state_machine.current_state.get_state_name() == "HurtState":
		return

	# Tick flip and jump cooldown timers
	if flip_timer > 0:
		flip_timer -= delta
	else:
		can_flip = true

	if jump_timer > 0:
		jump_timer -= delta
	else:
		can_jump = true

	# Sync attack range with current weapon
	if player.weapon != null:
		player.attack_range = player.original_attack_range + player.weapon.range_diff
	else:
		player.attack_range = player.original_attack_range

	navigate()

	# Skip combat logic during weapon search
	if state == State.SEARCH_WEAPON:
		return

	if enemy != null and !enemy.dead:
		var distance = enemy.global_position - player.global_position

		if abs(distance.x) > player.attack_range - 20:
			# Try to throw if in range and cooldown is ready
			if player.weapon and player.will_throw:
				if abs(distance.x) > player.weapon.ai_throw_range and abs(distance.y) < 30 and abs(distance.x) < 250:
					if throw_timer <= 0:
						player.ai_state = player.Ai_State_Request.throw
			set_state(State.CHASE)

		elif abs(distance.x) < player.attack_range + 20 and state != State.WAIT:
			if state == State.FIGHT:
				if player.weapon_user and !player.weapon:
					var weapons: Array[WeaponPickup]
					for weapon in player.sight_bubble.get_overlapping_bodies():
						if weapon.is_in_group("weapons"):
							weapons.append(weapon)
					if !weapons.is_empty():
						set_state(State.SEARCH_WEAPON)
						return
				# Already in fight state — re-trigger attack directly
				player.ai_state = player.Ai_State_Request.attack
			else:
				set_state(State.FIGHT)
	else:
		# No valid target — return to patrol
		if state != State.WAIT:
			set_state(State.PATROL)

# =========================================
# NAVIGATION
# =========================================

func navigate() -> void:
	# Point raycasts in the direction the enemy is facing
	player.wall_cast.target_position = Vector2(player.direction * 50, 0)
	player.feet_cast.target_position = Vector2(player.direction * player.original_feet_target_position.x, player.original_feet_target_position.y)
	player.feet_cast.position.x = player.direction * 10
	player.platform_cast.target_position = Vector2(player.direction * player.original_plat_target_position.x, player.original_plat_target_position.y)
	player.platform_cast.position.x = player.direction * 10

	# Check sight bubble for the player
	var colliders = player.sight_bubble.get_overlapping_bodies()
	for body in colliders:
		if body.is_in_group("player"):
			player.sight_cast.target_position = body.global_position - player.global_position
			player.sight_cast.force_raycast_update()

			if player.sight_cast.is_colliding():
				var collider = player.sight_cast.get_collider()
				# Acquire target if line of sight is clear
				if collider and not collider.is_in_group("enviroment") and enemy == null:
					enemy = body
				# Lose target if something is in the way
				elif collider and collider.is_in_group("enviroment") and enemy != null:
					lose_enemy(player.lose_time)

		if enemy == null and state != State.WAIT:
			set_state(State.PATROL)

	# Flip direction if walking into a wall
	var wall_collider = player.wall_cast.get_collider()
	if wall_collider != null and wall_collider.is_in_group("enviroment") and enemy == null:
		_flip()

# Enemy body is above the player character — fall down to follow
	if enemy != null and player.global_position.y - enemy.global_position.y < -30:
		player.ai_state = player.Ai_State_Request.fall
		player.update_ai_request()
		return

	# Enemy body is below the player character — jump up to follow
	if enemy != null and player.is_on_floor():
		if player.follow_up and (state == State.CHASE or state == State.SEARCH_WEAPON):
			# Jump up toward a platform if enemy is higher
			if player.platform_cast.is_colliding() and player.global_position.y - enemy.global_position.y > 32:
				var platform = player.platform_cast.get_collider()
				if platform != null and platform.is_in_group("enviroment"):
					player.ai_state = player.Ai_State_Request.jump
					player.update_ai_request()
			# Jump over a ledge gap even if no platform detected
			elif !player.feet_cast.is_colliding() and player.is_on_floor() and player.global_position.y - enemy.global_position.y > 10:
				player.ai_state = player.Ai_State_Request.jump
				player.update_ai_request()

	# Flip at ledge edges while patrolling
	if player.is_on_floor() and player.feet_cast.get_collider() == null:
		if state == State.PATROL:
			_flip()

# =========================================
# CONTROL FUNCTIONS
# =========================================

func _face_towards(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	# Flip to face the target if currently facing away
	if (target.global_position.x > player.global_position.x and player.direction == -1) or \
	   (target.global_position.x < player.global_position.x and player.direction == 1):
		_flip()

signal moved
func _move_towards_x(target: float, _sprint: bool = false) -> void:
	if player.state_machine.current_state.get_state_name() == "HurtState":
		return

	var distance_to_target = target - player.global_position.x

	# Face the correct direction
	if distance_to_target > 0 and player.direction == -1:
		_flip()
	elif distance_to_target < 0 and player.direction == 1:
		_flip()

	player.ai_state = player.Ai_State_Request.run
	is_sprinting = _sprint

	# Stop if close enough or about to walk off a ledge
	if player.state_machine.current_state.get_state_name() == "RunState" and !can_flip:
		distance_to_target = target - player.global_position.x
		if abs(distance_to_target) < 10 or (!player.feet_cast.is_colliding() and state == State.PATROL):
			moved.emit()
			is_sprinting = false
			return

func lose_enemy(time: float) -> void:
	# Currently disabled — enemies never lose sight of the player
	return

func _flip() -> void:
	if !can_flip:
		return
	# Reset patrol target to origin when flipping during patrol
	if state == State.PATROL:
		ran_patrol_x = patrol_origin
	flip_timer = flip_time
	player.flip_h = !player.flip_h
	can_flip = false
