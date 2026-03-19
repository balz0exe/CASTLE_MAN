#throw_state.gd
extends EnemyState

func enter(_prev_state):
	if state_machine.monitor:print("Entered Throw State")

func exit():
	if state_machine.monitor:print("Exited Throw State")

func physics_update(delta):
	if player.velocity.y > 0:
		player.velocity.y = 0
	player.velocity.x = move_toward(player.velocity.x, 0, player.friction * 100 * delta)
	if player.direction == 1:
		player.flip_h = false
	if player.direction == -1:
		player.flip_h = true
	if player.throw:
		player.has_weapon = false
		var projectile = load(player.throw_path)
		projectile = projectile.instantiate()
		projectile.from = player
		player.weapon.queue_free()
		projectile.global_position = player.global_position
		player.get_parent().add_child(projectile)
		projectile.sprite.flip_h = player.flip_h
		if player.flip_h:
			projectile.global_position = Vector2(projectile.global_position.x - 15, projectile.global_position.y - 15)
		if not player.flip_h:
			projectile.global_position = Vector2(projectile.global_position.x + 15, projectile.global_position.y - 15)
		projectile.apply_impulse(Vector2(player.direction * projectile.throw_speed * 5, -100), Vector2(0, 20))
		state_machine.change_state("IdleState")

func update_animation():
	player.animation.play("throw")
	if player.attack:
		player.animation.frame = 0

func update_input():
	pass

func get_state_name():
	return "ThrowState"
