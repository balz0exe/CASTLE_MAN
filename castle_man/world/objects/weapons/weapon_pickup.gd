extends RigidBody2D
class_name WeaponPickup

var sprite = Sprite2D
var coll = CollisionShape2D
var hit_box = HitBox
var hit_box_coll = CollisionShape2D
var interaction = Area2D
var interaction_coll = CollisionShape2D

@export var ranged: bool = false
@export var throw_speed = 100
@export var throw_damage = 5
@export var res: WeaponResource

var contact_monitor_timer: float = 0.0
var equip_delay_timer: float = 0.0
var equip_delay: float = 0.5
var from: CharacterBody2D
var thrown: bool = false
var hit_box_original_pos: Vector2
var animated: Dictionary = {
	"true": false,
	"h_frames": 1,
	"v_frames": 1,
}
var played: bool = false
var projectile: bool = false
var proj_persist: bool = false
var powerup: bool = false
var powerup_gd: Script
var instant: bool = false
var persist: bool = false

var direction: int = 1

var behavior: Script
var behavior_node: Node

var pickup_timer: float = 0.0
var fire_timer: float = 0.0
var ignore_enemies: bool = false
var ignore_objects: bool = false

signal hit(target)
signal throw

func _ready() -> void:
	#print("WeaponPickup created: ", get_instance_id(), " res: ", res)
	
	sprite = Sprite2D.new()
	coll = CollisionShape2D.new()
	hit_box = HitBox.new()
	hit_box_coll = CollisionShape2D.new()
	interaction = Area2D.new()
	interaction_coll = CollisionShape2D.new()
	
	contact_monitor = true
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	equip_delay_timer = equip_delay
	add_child(sprite)
	add_child(coll)
	collision_layer = 0
	collision_mask = 1
	hit_box.add_child(hit_box_coll)
	add_child(hit_box)
	interaction.add_child(interaction_coll)
	add_child(interaction)
	interaction.collision_layer = 0
	interaction.collision_mask = 2
	interaction.body_entered.connect(_on_body_entered)
	hit_box_original_pos = hit_box.coll.position
	
	pickup_timer = 2
	
	set_collision_layer_value(3, true)
	
	connect("hit", on_hit)
	connect("throw", on_thrown)
	
	set_values()
	
	if powerup and !persist:
		await Game.wait_for_seconds(10)
		await Game.fade_out_sprite(self, 5)
		queue_free()

func set_values() -> void:
	#while res == null and get_tree() != null:
		#await get_tree().process_frame
	if res == null:
		return
	behavior = res.pickup_script
	if behavior != null:
		behavior_node = Node.new()
		behavior_node.set_script(behavior)
		add_child(behavior_node)
	sprite.texture = res.image
	throw_damage = res.throw_damage
	throw_speed = res.throw_speed
	ranged = res.ranged
	var interaction_shape = RectangleShape2D.new()
	interaction_shape.size = Vector2(10, 10)
	interaction_coll.set_deferred("shape", interaction_shape)
	var hit_shape = CircleShape2D.new()
	hit_shape.radius = res.hit_box_radius
	hit_box_coll.set_deferred("shape", hit_shape)
	hit_box_coll.set_deferred("position", res.hit_box_pos)
	var body_shape = RectangleShape2D.new()
	body_shape.size = Vector2(5, 5)
	coll.set_deferred("shape", body_shape)
	animated = {
		"true": res.animated["true"],
		"h_frames": res.animated["h_frames"],
		"v_frames": res.animated["v_frames"],
		"range": res.animated["range"]
	}
	sprite.hframes = animated["h_frames"]
	sprite.vframes = animated["v_frames"]
	projectile = res.projectile
	proj_persist = res.proj_persist
	powerup = res.powerup
	if powerup:
		powerup_gd = res.powerup_gd
		instant = res.instant
		persist = res.persist
	
	if projectile:
		fire_timer = 0.2
	
	add_to_group("objects")
	if projectile: add_to_group("projectiles")
	if !powerup: add_to_group("weapons")
	elif is_in_group("weapons"): remove_from_group("weapons")
	

var animation_timeout: float = 0.0
func animate(rate: float = 0.2, _range: int = animated["range"]):
	animation_timeout = 0.1
	if !played:
		played = true
		sprite.frame = 0
		for frame in range(_range - 1):
			await Game.wait_for_seconds(rate)
			sprite.frame += 1
		played = false
		sprite.frame = 0

func _physics_process(delta: float) -> void:
	if powerup and animated:
		animate()
	if pickup_timer > 0:
		pickup_timer -= delta
	if animation_timeout > 0:
		animation_timeout -= delta
	if equip_delay_timer > 0:
		equip_delay_timer -= delta
	if fire_timer > 0:
		fire_timer -= delta

	var velocity = linear_velocity.length() / 20

	if picked_up or (projectile and !proj_persist and abs(linear_velocity.x) < 1):
		queue_free()

	# Drive direction and flip from actual velocity, not sprite state
	if linear_velocity.x < -0.1:
		direction = -1
		sprite.flip_h = true
		hit_box_coll.position.x = hit_box_original_pos.x * -2
	elif linear_velocity.x > 0.1:
		direction = 1
		sprite.flip_h = false
		hit_box_coll.position.x = hit_box_original_pos.x

	if velocity > 10:
		if powerup: hit_box_coll.disabled = true
		else: hit_box_coll.disabled = false
	else:
		thrown = false
		hit_box_coll.set_deferred("disabled", true)
		if projectile and fire_timer <= 0: hit.emit(self)
	check_contacts(delta)

func check_contacts(delta) -> void:
	if contact_monitor_timer > 0:
		interaction.monitoring = true
		contact_monitor_timer -= 1 * delta
		return
	contact_monitor_timer = 0.5
	interaction.monitoring = false

var picked_up = false

func _on_body_entered(body: Node2D) -> void:
	#print("body_entered: ", body.name, " | picked_up: ", picked_up, " | has_weapon: ", body.get("has_weapon"), " | claimed: ", Game.claimed_pickups.has(get_instance_id()))
	if (!powerup and picked_up) or (powerup and body.is_in_group("enemies")):
		return
	if body.has_method("equip_weapon") and equip_delay_timer <= 0:
		if (body.is_in_group("enemies") and ((ranged or powerup) or pickup_timer > 0)) or body.dead:
			return
		if body.is_in_group("player") or (body.is_in_group("enemies") and body.weapon_user):
				if powerup:
					if body.is_in_group("enemies") or (Game.get_player().powerup!= null and !instant):
						return
					var _powerup = Powerup.new()
					_powerup.set_script(powerup_gd)
					_powerup.name = res.weapon_name
					if !instant: Game.get_player().powerup = _powerup
					else: Game.get_player().add_child(_powerup)
					queue_free()
				elif not body.has_weapon:
					if !Game.claim_pickup(self):
						return
					interaction.set_deferred("monitoring", false)
					interaction.set_deferred("monitorable", false)
					picked_up = true
					hide()
					var weapon = res
					if body.is_in_group("enemies"):
						body.found_weapon = null
					body.equip_weapon(weapon, self)

func connect_interaction() -> void:
	if interaction != null:
		interaction.connect("body_entered", Callable(self, "_on_body_entered"))

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		Game.release_pickup(self)

#Empty Functions

func on_hit(target):
	if !proj_persist and target.is_in_group("enviroment"):
		queue_free()
	if behavior != null and behavior_node.has_method("on_hit"):
		behavior_node.on_hit(target)

func on_thrown(delta):
	if behavior != null and behavior_node.has_method("on_thrown"):
		behavior_node.on_thrown(delta)
