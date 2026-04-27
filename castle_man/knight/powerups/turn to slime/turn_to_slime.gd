extends Powerup

var time: float = 1
@onready var area: Area2D = Area2D.new()
@onready var coll: CollisionShape2D = CollisionShape2D.new()

func _physics_process(_delta: float) -> void:
	for body in area.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			turn_to_slime(body)

func _ready() -> void:
	super()
	var shape = CircleShape2D.new()
	coll.shape = shape
	shape.radius = 150
	area.set_collision_layer_value(1, false)
	area.set_collision_mask_value(1, false)
	area.set_collision_mask_value(2, true)

	area.add_child(coll)
	player.add_child(area)
	Game.spawn_particle_oneshot("res://fx/particle_fx/alchemy_magic.tscn", Game.get_player(), Vector2(0, -20), null, false)

	await Game.wait_for_seconds(time)
	area.queue_free()
	queue_free()
	
func turn_to_slime(body: Node2D):
	var pos = body.global_position
	var slime = Game.spawn_object(load("res://enemies/scenes/slime.tscn"), pos)
	slime.ENEMY_AI.enemy = Game.get_player()
	Game.get_game_handler().enem_count -= 1
	body.queue_free()
	for i in range(randi_range(3,5)):
		Game.spawn_particle_oneshot("res://fx/particle_fx/smoke.tscn", slime, Vector2.ZERO, null, false)
