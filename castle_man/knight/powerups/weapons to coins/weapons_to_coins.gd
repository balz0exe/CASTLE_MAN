extends Powerup

var timer: float
@onready var area: Area2D = Area2D.new()
@onready var coll: CollisionShape2D = CollisionShape2D.new()

func _physics_process(delta: float) -> void:
	for body in area.get_overlapping_bodies():
		if body.is_in_group("weapons"):
			turn_to_coins(body)

func _ready() -> void:
	super()
	var shape = CircleShape2D.new()
	coll.shape = shape
	shape.radius = 150
	area.set_collision_layer_value(1, false)
	area.set_collision_mask_value(1, false)
	area.set_collision_mask_value(3, true)

	area.add_child(coll)
	player.add_child(area)
	Game.spawn_particle_oneshot("res://fx/particle_fx/alchemy_magic.tscn", Game.get_player(), Vector2(0, -20), null, false)

	await Game.wait_for_seconds(6)
	area.queue_free()
	queue_free()
	
func turn_to_coins(body: Node2D):
	var pos = body.global_position
	#Game.spawn_particle_oneshot("Smoke particles", body)
	for i in range(randi_range(3,5)):
		var coin = Game.spawn_object(load("res://knight/powerups/coins/coin.tres"), pos)
		coin.apply_impulse(Vector2(randi_range(-200,200), randi_range(5,12))*Engine.time_scale)
	body.queue_free()
