extends Node
class_name EnemyState

var state_machine: Node
var player: CharacterBody2D
var version: int

func enter(_prev_state): pass
func exit(): pass
func physics_update(_delta): pass
func update(_delta): pass
func update_input(): pass
func update_animation(): pass
func get_state_name() -> String: return "UnnamedState"
