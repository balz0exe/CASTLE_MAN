#attack_state.gd
extends PlayerState

var up_down_attack : bool
var up_down
var attacking : bool
var buffered_attack : bool
var played : bool = false
var clear: bool = false
var prev_state: String
var run_attack: bool

func attack():
	if !attacking:
		if Input.is_action_pressed("ui_up") or (not player.is_on_floor() and Input.is_action_pressed("ui_down")):
			up_down_attack = true
			up_down = Input.get_axis("ui_up", "ui_down")
		else:
			up_down_attack = false
		player.combo_counter += 1
		if player.combo_counter > player.combo_count or player.stamina <= 0:
			start_exit()
			return
		if player.weapon: player.stamina -= player.weapon.stamina_cost
		played = false
		attacking = true

func enter(_prev_state):
	if not player.combo_cooldown_timer > 0:
		player.combo_counter = 0
	run_attack = false
	prev_state = _prev_state.get_state_name()
	if prev_state == "RunState":
		run_attack = true
	if state_machine.monitor:print("Entered Attack State")
	if player.weapon == null:
		start_exit()
		return
	clear = true
	if !player.weapon.ranged: attack()

func start_exit() -> void:
	if player.is_on_floor():
		state_machine.change_state("IdleState")
	else:
		state_machine.change_state("FallState")

func exit():
	attacking = false
	#if player.combo_cooldown_timer <= 0 and player.combo_counter > player.combo_count - 1:
		#player.combo_cooldown_timer = player.combo_cooldown
	if state_machine.monitor:print("Exited Attack State")

func physics_update(delta):
	if clear and player.weapon:
		if player.animation.animation.contains("attack"):
			if !player.is_on_floor():
				player.velocity.y = -50
			if !up_down_attack:
				if player.combo_counter == player.combo_count and run_attack:
					player.velocity.x = player.max_speed * player.direction * delta * player.weapon.thrust_speed_factor * 100
				elif !run_attack:
					player.velocity.x = player.max_speed * player.direction * delta * player.weapon.thrust_speed_factor * 10
				elif run_attack:
					player.velocity.x += player.acceleration/2 * Input.get_axis("ui_left", "ui_right") * delta
					player.velocity.x = clamp(player.velocity.x, -player.max_speed, player.max_speed)
			else:
				if up_down == -1:
					player.velocity.x = move_toward(player.velocity.x, 0, delta * 500)
				if up_down == 1:
					check_pogo(delta)
		if (player.combo_reset_timer <= 0 and !attacking):
			start_exit()
	elif !player.weapon:
		state_machine.change_state("IdleState")

func check_pogo(delta):
	await player.hit
	player.velocity.y -= delta * 100
	player.velocity.x -= delta * 100 * player.direction

func update_animation():
	if clear:
		if player.combo_counter == 0: return
		if !played and player.weapon != null:
			if player.weapon.ranged: return
			played = true
			if !up_down_attack:
				player.animation.play("attack " + str(player.weapon.anim[player.combo_counter - 1]))
			else:
				if up_down != -1:
					player.animation.play("attack down")
				else:
					player.animation.play("attack up")
			async_animations()
			if buffered_attack and version == player.state_version and player.combo_counter < player.combo_count:
				buffered_attack = false
				attack()

func async_animations():
	await player.animation.animation_finished
	if version != player.state_version:
		return
	player.combo_reset_timer = player.weapon.combo_reset_time
	Game.play_sfx(player.hit_sfx, Game.sfx_volume, player)
	attacking = false
	if !up_down_attack:
		if player.is_on_floor() and !run_attack: player.velocity.x = 0
		if run_attack: player.velocity.x = player.velocity.x/2
	if run_attack:
		player.animation.play("run")
	else:
		player.animation.play("idle")

func update_input():
	if clear:
		if not Input.is_action_pressed("ui_right") and not Input.is_action_pressed("ui_left"):
			run_attack = false
		if Input.is_action_just_pressed("attack"):
			if !attacking:
				attack()
			else:
				buffered_attack = true

func get_state_name():
	return "AttackState"
