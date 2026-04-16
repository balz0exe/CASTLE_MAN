extends Resource
class_name WeaponResource

@export_group("BASIC")
@export var weapon_name: String
@export var image: CompressedTexture2D
@export var animated: Dictionary = {
	"true": false,
	"h_frames": 1,
	"v_frames": 1,
	"range": 1
	}
@export var ranged: bool = false
@export var projectile: bool = false
@export var powerup: bool = false
@export var powerup_gd: Script
@export var knockback = 5
@export var damage = 2
@export_group("EQUIP")
@export var hurt_box_shape: Shape2D
@export var hurt_box_offset: Vector2
@export var projectile_res: Resource
@export var throwable: bool = false
@export var ai_throw_range: int = 150
@export var range_diff: int = 0
@export var stamina_cost = 5
@export var thrust_speed_factor = 1.0
@export var combo_count := 4
@export var combo_reset_time: float = 0.2
@export var anim: Array[String]
@export var speed_scale: = 1.0
@export var dash_attack = false
@export var offset = Vector2(5, 0)
@export var sync_data = {
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
			0: { "position": Vector2(-15 , 0), "rotation": deg_to_rad(215) }
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
@export_group("THROW")
@export var throw_speed = 100
@export var throw_damage = 5
@export var hit_box_pos: Vector2
@export var hit_box_radius = 5
@export_group("SCRIPTS")
@export var pickup_script: Script
@export var item_script: Script
