#attack_state.gd
extends EnemyState

var up_down_attack : bool = false
var up_down
var attacking : bool
var attack_counter : bool
var played : bool = false
var clear: bool = false

func attack():
	if !played:
		if player.weapon: if player.weapon.ranged: return
		played = true
		if !up_down_attack:
			if player.weapon:
				player.animation.play("attack " + str(player.weapon.anim[player.combo_counter - 1]))
				Game.play_sfx(load("res://fx/audio_fx/sword_swing.wav"), Game.sfx_volume, player)
			else:
				player.animation.play("attack 1")
				Game.play_sfx(player.hit_sfx, Game.sfx_volume, player)
				player.combo_reset_timer = randf_range(0.5, 1.5) * player.combo_reset_time
		player.attacked.emit()
		player.hit_box.coll.disabled = false
		player.velocity.x += 10 * player.direction
		await player.animation.animation_finished
		if version != player.state_version:
			return
		start_exit()

func enter(_prev_state):
	if player.combo_reset_timer > 0:
		start_exit()
		return
	if !player.basic_attack:
		player.velocity.x = 0
	if player.combo_cooldown_timer <= 0:
		player.combo_counter = 0
	if player.weapon and player.weapon.combo_count == player.combo_counter + 1:
		player.combo_counter = 0
		player.combo_reset_timer = randf_range(0.5, 1.5) * player.combo_reset_time
	elif player.weapon:
		player.combo_counter += 1
	if state_machine.monitor:print("Entered Attack State")
	if player.combo_counter == 1:
		player.animation.play("wind up")
		await player.animation.animation_finished
		if version != player.state_version:
			return
	clear = true
	attack()

func start_exit() -> void:
	if player.is_on_floor() or player.flying:
		state_machine.change_state("IdleState")
	else:
		state_machine.change_state("FallState")

func disable_hitbox() -> void:
	player.hit_box.coll.disabled = true

func exit():
	call_deferred("disable_hitbox")
	if player.combo_cooldown_timer <= 0 or player.basic_attack:
		player.combo_cooldown_timer = player.combo_cooldown
	attacking = false
	played = false
	if state_machine.monitor:print("Exited Attack State")

func physics_update(_delta):
	if clear:
		if player.animation.animation.contains("attack"):
			if player.is_on_floor() and !player.flying:
				player.velocity.x = 50 * player.direction

func update_animation():
	pass

func async_animations():
	await player.animation.animation_finished
	if version != player.state_version:
		return
	Game.play_sfx(player.hit_sfx, Game.sfx_volume, player)
	attacking = false
	if player.is_on_floor() or player.flying: player.velocity.x = 0
	player.animation.play("idle")

func update_input():
	pass

func get_state_name():
	return "AttackState"
