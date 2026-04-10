class_name ParticleOneshot
extends CPUParticles2D

var fade_time := 0.5
var fading := false

var player: Node2D

signal done_emitting

func _ready() -> void:
	emitting = true
	player = get_parent()
	var timer = Timer.new()
	var time = lifetime - 0.5
	if time > 0:
		timer.wait_time = lifetime - 0.2
	else:
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
			done_emitting.emit()
			queue_free()
