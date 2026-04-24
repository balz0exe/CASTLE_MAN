extends Control

@export var life_sprite_texture: Texture2D  # Assign your sprite texture in the Inspector
@onready var life_sprite_template = $Sprite2D  # Your existing Sprite2D child

var player: Node

func _ready():
	# Get the player node — adjust the path to match your scene tree
	player = Game.get_player()
	player.connect("player_died", update_lives_display)

func _process(_delta: float) -> void:
	if Game.get_level().name == "TitleScreen":
		visible = false
	else:
		visible = true
	if Game.get_player():
		player = Game.get_player()
		update_lives_display()

func update_lives_display():
	if not Game.get_player():
		return
	else:
		player = Game.get_player()

	for child in get_children():
		if child != life_sprite_template:
			child.queue_free()

	life_sprite_template.visible = false

	var spacing = 30
	var total_width = player.lives * spacing
	var start_x = -total_width / 2.0 + spacing / 2.0

	for i in range(player.lives):
		var sprite = life_sprite_template.duplicate()
		sprite.visible = true
		sprite.position = Vector2(start_x + i * spacing, 0)
		add_child(sprite)
