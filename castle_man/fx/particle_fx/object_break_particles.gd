extends ParticleOneshot

var points = []
var colors = []

func _ready() -> void:
	super()
	connect("done_emitting", _done_emitting)
	var frames = player.anim.sprite_frames
	var image = frames.get_frame_texture("default", 0).get_image()
	scale = player.anim.scale
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
	modulate = player.anim.modulate

func _done_emitting():
	player.queue_free()
