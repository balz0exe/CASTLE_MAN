extends RigidBody2D
class_name WeaponPickup

var sprite = Sprite2D.new()
var coll = CollisionShape2D.new()
var hit_box = HitBox.new()
var hit_box_coll = CollisionShape2D.new()
var interaction = Area2D.new()
var interaction_coll = CollisionShape2D.new()

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

func _ready() -> void:
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
	set_values()
	hit_box_original_pos = hit_box.coll.position

func set_values() -> void:
	while res == null:
		await get_tree().process_frame
	sprite.texture = res.image
	throw_damage = res.throw_damage
	throw_speed = res.throw_speed
	ranged = res.ranged
	interaction_coll.shape = RectangleShape2D.new()
	interaction_coll.shape.size = Vector2(10, 10)
	hit_box_coll.shape = CircleShape2D.new()
	hit_box_coll.shape.radius = 5
	hit_box_coll.position = res.hit_box_pos
	coll.shape = RectangleShape2D.new()
	coll.shape.size = Vector2(5, 5)
	animated = {
		"true": res.animated["true"],
		"h_frames": res.animated["h_frames"],
		"v_frames": res.animated["v_frames"],
		"range": res.animated["range"]
	}
	sprite.hframes = animated["h_frames"]
	sprite.vframes = animated["v_frames"]

var animation_timeout: float = 0.0
func animate(rate: float = 0.2, _range: int = animated["range"]):
	animation_timeout = 0.1
	if !played:
		played = true
		sprite.frame = 0
		for frame in range(_range - 1):
			await Game.wait_for_seconds(rate)
			sprite.frame += 1
		while animation_timeout > 0:
			await get_tree().process_frame
		played = false
		sprite.frame = 0

func _physics_process(delta: float) -> void:
	if animation_timeout > 0:
		animation_timeout -= delta
	if equip_delay_timer > 0:
		equip_delay_timer -= delta
	var velocity = linear_velocity.length()
	if sprite.flip_h:
		hit_box_coll.position.x = hit_box_original_pos.x * -2
	else:
		hit_box_coll.position.x = hit_box_original_pos.x
	if velocity > 10:
		hit_box_coll.disabled = false
	else:
		thrown = false
		hit_box_coll.disabled = true
	check_contacts(delta)

func check_contacts(delta) -> void:
	if contact_monitor_timer > 0:
		interaction.monitoring = true
		contact_monitor_timer -= 1 * delta
		return
	contact_monitor_timer = 0.5
	interaction.monitoring = false

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("equip_weapon") and equip_delay_timer <= 0:
		if body.is_in_group("enemies") and ranged:
			return
		if body.is_in_group("player") or (body.is_in_group("enemies") and body.weapon_user):
			if not body.has_weapon:
				var weapon = res
				if body.is_in_group("enemies"):
					body.found_weapon = null
				body.call_deferred("equip_weapon", weapon, self)

func connect_interaction() -> void:
	if interaction != null:
		interaction.connect("body_entered", Callable(self, "_on_body_entered"))
