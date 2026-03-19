#state_machine.gd
extends Node

var current_state: EnemyState
var states: Dictionary = {}
var player: CharacterBody2D

@export var monitor : bool = false

func init(player_ref):
	
	#accept player referance
	player = player_ref

	#preload all states
	states["IdleState"] = preload("res://enemies/enemy_states/idle_state.gd").new()
	states["RunState"] = preload("res://enemies/enemy_states/run_state.gd").new()
	states["FallState"] = preload("res://enemies/enemy_states/fall_state.gd").new()
	states["JumpState"] = preload("res://enemies/enemy_states/jump_state.gd").new()
	states["RollState"] = preload("res://enemies/enemy_states/roll_state.gd").new()
	states["AttackState"] = preload("res://enemies/enemy_states/attack_state.gd").new()
	states["ThrowState"] = preload("res://enemies/enemy_states/throw_state.gd").new()
	states["BlockState"] = preload("res://enemies/enemy_states/block_state.gd").new()
	states["HurtState"] = preload("res://enemies/enemy_states/hurt_state.gd").new()
	states["DieState"] = preload("res://enemies/enemy_states/die_state.gd").new()
	
	for state in states.values():
		state.state_machine = self
		state.player = player
		add_child(state)

	current_state = states["IdleState"]
	current_state.enter(null)

func input(event):
	current_state.input(event)

func _physics_process(delta):
	current_state.physics_update(delta)

func _process(delta):
	current_state.update(delta)

func update_animation():
	current_state.update_animation()

func change_state(new_state_name: String):
	var new_state = states.get(new_state_name)
	if not (new_state == null or new_state == current_state):
		current_state.exit()
		current_state = new_state
		player.state_version += 1
		current_state.enter(current_state)
		current_state.version = player.state_version

#func _change_state(new_state_name: String):
