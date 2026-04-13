extends Area2D
class_name WeaponItem

@export var weapon_name: String
@export var throw_path: String
@export var projectile_path: String
@export var throwable: bool = false
@export var ranged: bool = false
@export var damage = 2
@export var range_diff: int = 0
@export var stamina_cost = 5
@export var knockback = 5
@export var thrust_speed_factor = 1.0
@export var combo_count := 4
@export var combo_reset_time: float = 0.2
@export var anim: Array[String]
@export var speed_scale: = 1.0
@export var dash_attack = false

@onready var sprite: Sprite2D = $Sprite
@onready var hurtbox = $Hurtbox

var owner_player: Node = null
var animation_sync_data := {}
var flip_h = false
var can_damage = false
var offset: Vector2 = Vector2(5,0)

func _ready():
	hurtbox.disabled = true
	define_default_sync_data()

func _physics_process(_delta: float) -> void:
	monitorable = can_damage
	hurtbox.disabled = !can_damage

func on_equip(player: Node) -> void:
	owner_player = player
	owner_player.throw_path = throw_path
	owner_player.combo_cooldown = combo_reset_time
	flip_h = player.animation.flip_h
	update_attack_pattern(combo_count, anim)

func throw() -> void:
	Game.play_sfx(owner_player.hit_sfx, Game.sfx_volume, owner_player)
	if owner_player.weapon.throwable: owner_player.has_weapon = false
	var projectile
	if owner_player.weapon.throwable:
		projectile = load(owner_player.throw_path)
	elif owner_player.weapon.ranged:
		projectile = load(owner_player.weapon.projectile_path)
	projectile = projectile.instantiate()
	projectile.from = owner_player
	if !owner_player.weapon.ranged: owner_player.weapon.queue_free()
	owner_player.get_parent().add_child(projectile)
	projectile.sprite.flip_h = owner_player.flip_h
	projectile.global_position = Vector2(owner_player.global_position.x + owner_player.direction * 15, owner_player.global_position.y - 5)
	projectile.apply_impulse(Vector2(owner_player.direction * projectile.throw_speed * 5, -100))
	projectile.thrown = true
	owner_player.state_machine.change_state("IdleState")

func update_attack_pattern(combo: int, animations: Array[String]) -> void:
	if owner_player and owner_player.has_method("set_attack_pattern"):
		owner_player.set_attack_pattern(combo, animations)

func sync_with_animation(anim_name: String, frame: int, anim_flip_h: bool) -> void:
	if owner_player.animation.animation.contains("attack"):
		owner_player.animation.speed_scale = speed_scale
	else:
		owner_player.animation.speed_scale = 1
	if (owner_player.animation.animation == "attack 3" and owner_player.animation.frame == 0) or (owner_player.animation.animation == "throw" and owner_player.animation.frame == 0) or (owner_player.animation.animation == "attack up" and owner_player.animation.frame == 1) or (owner_player.animation.animation == "block" and owner_player.animation.frame == 1):
		sprite.z_index = 1
	else:
		sprite.z_index = 0
	if anim_name.begins_with("attack") and frame == 2:
		can_damage = true
	else:
		can_damage = false
	var data := get_frame_data(anim_name, frame)
	if data:
		var pos = data.position
		var rot = data.rotation
		if owner_player.animation.flip_h:
			pos.x = -pos.x - (2* get_parent().position.x)
			rot = -rot
		global_position = get_parent().to_global(pos + Vector2(offset.x * owner_player.direction, offset.y))
		if owner_player.is_in_group("player") and owner_player.state_machine.current_state.get_state_name() == "HurtState" or owner_player.animation.animation == "attack up":
			rotation = -rot
			global_position = get_parent().to_global(pos + Vector2(offset.x * -owner_player.direction, offset.y))
		else:
			rotation = rot
		show()
		scale.x = -1 if anim_flip_h else 1
	else:
		hide()

func get_frame_data(anim_name: String, frame: int) -> Dictionary:
	if anim_name in animation_sync_data:
		var anim_data = animation_sync_data[anim_name]
		if frame in anim_data:
			return anim_data[frame]
	return {}

func define_default_sync_data():
	animation_sync_data = {
		"idle": {
			0: { "position": Vector2(0, 0), "rotation": 0 },
			1: { "position": Vector2(3, 2), "rotation": deg_to_rad(5) },
			2: { "position": Vector2(2, 2), "rotation": deg_to_rad(5) },
			3: { "position": Vector2(1, 1), "rotation": deg_to_rad(3) },
		},
		"block": {
			0: { "position": Vector2(0, 0), "rotation": 0 },
			1: { "position": Vector2(-17, 8), "rotation": deg_to_rad(-95) },
			2: { "position": Vector2(2, 2), "rotation": deg_to_rad(5) },
		},
		"run": {
			0: { "position": Vector2(1, -1), "rotation": deg_to_rad(-5) },
			1: { "position": Vector2(2, -0.5), "rotation": deg_to_rad(-10) },
			2: { "position": Vector2(0, 0), "rotation": deg_to_rad(-5) },
			3: { "position": Vector2(-1, -1), "rotation": deg_to_rad(0) },
			4: { "position": Vector2(-2, -0.5), "rotation": deg_to_rad(5) },
			5: { "position": Vector2(0, 0), "rotation": deg_to_rad(5) },
		},
		"jump": {
			0: { "position": Vector2(0, -5.5), "rotation": deg_to_rad(10) },
			1: { "position": Vector2(1, -5), "rotation": deg_to_rad(-45) },
			2: { "position": Vector2(1, -5), "rotation": deg_to_rad(-70) },
			3: { "position": Vector2(2, -4.5), "rotation": deg_to_rad(-90) },
		},
		"fall": {
			0: { "position": Vector2(0, -5.5), "rotation": deg_to_rad(-90) },
			1: { "position": Vector2(0, -4.5), "rotation": deg_to_rad(-90) },
			2: { "position": Vector2(0, -5.5), "rotation": deg_to_rad(-90) },
		},
		"throw": {
			0: { "position": Vector2(-18, 22), "rotation": deg_to_rad(215) }
		},
		"attack 1": {
			0: { "position": Vector2(-4, -6), "rotation":deg_to_rad(-50) },
			1: { "position": Vector2(12, -4), "rotation": deg_to_rad(0) },
		},
		"attack 2": {
			0: { "position": Vector2(7, -3), "rotation": deg_to_rad(-5) },
			1: { "position": Vector2(8, 3), "rotation": deg_to_rad(25) },
		},
		"attack 3": {
			0: { "position": Vector2(-17, 0), "rotation": deg_to_rad(-90) },
			1: { "position": Vector2(6, -1), "rotation": deg_to_rad(-35) },
		},
		"attack up": {
			0: { "position": Vector2(5, -6), "rotation": deg_to_rad(-155) },
			1: { "position": Vector2(-20, -8), "rotation": deg_to_rad(-45) },
		},
		"attack down": {
			0: { "position": Vector2(-17, 7), "rotation": deg_to_rad(-90) },
			1: { "position": Vector2(6, -1), "rotation": deg_to_rad(-35) },
		},
		"roll": {
			4: { "position": Vector2(-6, 4), "rotation": 5 },
			5: { "position": Vector2(4, -6), "rotation": deg_to_rad(0) },
			6: { "position": Vector2(3, -2), "rotation": deg_to_rad(0) },
		},
		"wind up": {
			0: { "position": Vector2(3, 0), "rotation": deg_to_rad(-5) },
			1: { "position": Vector2(4, 6), "rotation": deg_to_rad(25) },
			2: { "position": Vector2(2, 7), "rotation": deg_to_rad(25) },
		},
	}
