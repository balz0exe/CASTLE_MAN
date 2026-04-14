extends Area2D
class_name WeaponItem

@export var weapon_name: String
@export var throw_path: Resource
@export var projectile_path: Resource
@export var throwable: bool = false
@export var ai_throw_range: int = 150
@export var ranged: bool = false
@export var damage = 2
@export var range_diff: int = 0
@export var stamina_cost = 5
@export var knockback = 5
@export var thrust_speed_factor = 1.0
@export var combo_count := 4
@export var combo_reset_time: float = 0.2
@export var anim: Array[String]
var animated: Dictionary = {
	"true": false,
	"h_frames": 1,
	"v_frames": 1,
}
@export var offset: Vector2 = Vector2(5,0)
@export var speed_scale: = 1.0
@export var dash_attack = false

@onready var sprite: Sprite2D = Sprite2D.new()

var owner_player: Node = null
var animation_sync_data := {}
var flip_h = false
var can_damage = false
var played: bool = false
var animation_timeout: float = 0.0

var weapon: Resource

func set_values():
	while weapon == null:
		await get_tree().process_frame
	sprite.texture = weapon.image
	anim = weapon.anim
	speed_scale = weapon.speed_scale
	dash_attack = weapon.dash_attack
	combo_reset_time = weapon.combo_reset_time
	combo_count = weapon.combo_count
	thrust_speed_factor = weapon.thrust_speed_factor
	knockback = weapon.knockback
	stamina_cost = weapon.stamina_cost
	range_diff = weapon.range_diff
	damage = weapon.damage
	ranged = weapon.ranged
	ai_throw_range = weapon.ai_throw_range
	throwable = weapon.throwable
	weapon_name = weapon.weapon_name
	animation_sync_data = weapon.sync_data
	offset = weapon.offset
	
	animated = {
		"true": weapon.animated["true"],
		"h_frames": weapon.animated["h_frames"],
		"v_frames": weapon.animated["v_frames"],
		"range": weapon.animated["range"]
	}
	sprite.hframes = animated["h_frames"]
	sprite.vframes = animated["v_frames"]
	

func _ready():
	add_child(sprite)
	

func _physics_process(delta: float) -> void:
	if animation_timeout > 0:
		animation_timeout -= delta
	if owner_player:
		sprite.offset = owner_player.animation.offset
	if owner_player.state_machine.current_state.get_state_name() == "AttackState" or owner_player.state_machine.current_state.get_state_name() == "ThrowState":
		animate()

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

func on_equip(player: Node, res: Resource) -> void:
	weapon = res
	set_values()
	owner_player = player
	owner_player.combo_cooldown = combo_reset_time
	flip_h = player.animation.flip_h
	update_attack_pattern(combo_count, anim)

func throw() -> void:
	Game.play_sfx(owner_player.hit_sfx, Game.sfx_volume, owner_player)
	if owner_player.weapon.throwable: owner_player.has_weapon = false
	var projectile
	projectile = WeaponPickup.new()
	projectile.res = weapon
	projectile.from = owner_player
	if !owner_player.weapon.ranged: owner_player.weapon.queue_free()
	owner_player.get_parent().add_child(projectile)
	projectile.sprite.flip_h = owner_player.flip_h
	projectile.global_position = Vector2(owner_player.global_position.x + owner_player.direction * 15, owner_player.global_position.y - 5)
	projectile.apply_impulse(Vector2(owner_player.direction * projectile.throw_speed * 5, -150))
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
