#state_machine.gd
extends Node

var current_state: PlayerState
var states: Dictionary = {}
var player: CharacterBody2D

@export var monitor : bool = false

signal state_changed

func init(player_ref):
	
	#accept player referance
	player = player_ref

	#preload all states
	states["IdleState"] = preload("res://knight/states/idle_state.gd").new()
	states["RunState"] = preload("res://knight/states/run_state.gd").new()
	states["FallState"] = preload("res://knight/states/fall_state.gd").new()
	states["JumpState"] = preload("res://knight/states/jump_state.gd").new()
	states["RollState"] = preload("res://knight/states/roll_state.gd").new()
	states["AttackState"] = preload("res://knight/states/attack_state.gd").new()
	states["ThrowState"] = preload("res://knight/states/throw_state.gd").new()
	states["BlockState"] = preload("res://knight/states/block_state.gd").new()
	states["HurtState"] = preload("res://knight/states/hurt_state.gd").new()
	states["DieState"] = preload("res://knight/states/die_state.gd").new()

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
	call_deferred("_change_state", new_state_name)

func _change_state(new_state_name: String):
	var new_state = states.get(new_state_name)
	if not (new_state == null or new_state == current_state) and not (new_state_name == "AttackState" and player.stamina <= player.weapon.stamina_cost) and not (new_state_name == "RollState" and player.stamina <= player.roll_stam_cost):
		current_state.exit()
		current_state = new_state
		player.state_version += 1
		current_state.version = player.state_version
		current_state.enter(current_state)
		state_changed.emit()
