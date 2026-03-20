#attack_state.gd
extends PlayerState

var up_down_attack : bool
var up_down
var attacking : bool
var buffered_attack : bool
var played : bool = false
var clear: bool = false
var prev_state: String

func attack():
	if !attacking:
		player.combo_counter += 1
		if player.combo_counter > player.combo_count or player.stamina <= 0:
			start_exit()
			return
		if player.weapon: player.stamina -= player.weapon.stamina_cost
		played = false
		attacking = true
		if Input.is_action_pressed("ui_up") or (not player.is_on_floor() and Input.is_action_pressed("ui_down")):
			up_down_attack = true
		else:
			up_down_attack = false

func enter(_prev_state):
	prev_state = _prev_state.get_state_name()
	print(prev_state)
	if player.combo_cooldown_timer > 0 or player.stamina <= 0:
		start_exit()
		return
	if state_machine.monitor:print("Entered Attack State")
	clear = true
	if !player.weapon.ranged: attack()

func start_exit() -> void:
	if player.is_on_floor():
		state_machine.change_state("IdleState")
	else:
		state_machine.change_state("FallState")

func exit():
	attacking = false
	if player.combo_cooldown_timer <= 0 and player.combo_counter > player.combo_count - 1:
		player.combo_cooldown_timer = player.combo_cooldown
	player.combo_counter = 0
	if state_machine.monitor:print("Exited Attack State")

func physics_update(delta):
	if clear and player.weapon:
		up_down = Input.get_axis("ui_up", "ui_down")
		if player.animation.animation.contains("attack"):
			if !player.is_on_floor():
				player.velocity.y = -50
			if player.combo_counter == player.combo_count:
				player.velocity.x = player.max_speed * player.direction * delta * player.weapon.thrust_speed_factor * 100
			elif prev_state != "RunState":
				player.velocity.x = player.max_speed * player.direction * delta * player.weapon.thrust_speed_factor * 10
		if prev_state == "RunState":
			player.velocity.x += player.acceleration/2 * Input.get_axis("ui_left", "ui_right") * delta
			player.velocity.x = clamp(player.velocity.x, -player.max_speed, player.max_speed)
		if player.combo_reset_timer <= 0 and !attacking:
			start_exit()
	elif !player.weapon:
		state_machine.change_state("IdleState")

func update_animation():
	if clear:
		if player.combo_counter == 0: return
		if !played:
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
	if player.is_on_floor(): player.velocity.x = 0
	if prev_state == "RunState": player.velocity.x = player.velocity.x/4
	player.animation.play("idle")

func update_input():
	if clear:
		if Input.is_action_just_pressed("attack"):
			if !attacking:
				attack()
			else:
				buffered_attack = true

func get_state_name():
	return "AttackState"
