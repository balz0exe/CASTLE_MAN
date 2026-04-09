class_name ParticleOneshot
extends CPUParticles2D

var fade_time := 0.5
var fading := false

func _ready() -> void:
	show_behind_parent = true
	emitting = true
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	add_child(timer)
	timer.start()
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	fading = true

func _process(delta: float) -> void:
	if fading:
		modulate.a -= delta / fade_time
		if modulate.a <= 0:
			queue_free()
