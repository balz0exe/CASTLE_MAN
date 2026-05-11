extends ParticleOneshot

var points = []
var colors = []

func _ready() -> void:
	super()
	connect("done_emitting", _done_emitting)
	var frames
	if player is AnimatedSprite2D:
		frames = player.sprite_frames
	elif player is Sprite2D:
		frames = null
	var image = player.texture.get_image() if frames == null else frames.get_frame_texture("die", 2).get_image()
	var half_size = Vector2(image.get_size()) / 2
	
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var pixel = image.get_pixel(x, y)
			if pixel.a > 0.5:
				points.append(Vector2(x, y) - half_size)
				colors.append(pixel)

	# Set the points and colors on the CPUParticles2D node
	amount = points.size()
	emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
	emission_points = PackedVector2Array(points)
	emission_colors = PackedColorArray(colors)

func _done_emitting():
	if player.get_parent().is_in_group("player"):
		return
	player.get_parent().queue_free()
