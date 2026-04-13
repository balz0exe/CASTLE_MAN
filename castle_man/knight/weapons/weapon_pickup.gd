extends RigidBody2D
class_name WeaponPickup

@onready var sprite = $Sprite2D
@onready var coll = $CollisionShape2D
@onready var hit_box = $HitBox
@onready var interaction = $InteractionArea

@export var ranged: bool = false

@export var throw_speed = 100
@export var throw_damage = 5
@export var equip_path: String = ""

var contact_monitor_timer: float = 0.0
var equip_delay_timer: float = 0.0
var equip_delay: float = 0.5

var from: CharacterBody2D
var thrown: bool = false

func _ready() -> void:
	call_deferred("connect_interaction")
	contact_monitor = true
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	equip_delay_timer = equip_delay
	init()

func init() -> void:
	pass

func _physics_process(delta: float) -> void:
	if equip_delay_timer > 0: equip_delay_timer -= delta * 1
	var velocity = linear_velocity.length()
	if velocity > 0:
		hit_box.monitorable = true
	else:
		thrown = false
		hit_box.monitorable = false
		
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
		if body.is_in_group("player") or body.weapon_user:
			if not body.has_weapon:
				var weapon = load(equip_path)
				if body.is_in_group("enemies"): body.found_weapon = null
				body.call_deferred("equip_weapon", weapon, self)

func connect_interaction() -> void:
	if interaction != null:
		interaction.connect("body_entered", Callable(self, "_on_body_entered"))
