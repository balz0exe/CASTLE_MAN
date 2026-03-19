extends Node2D

@onready var timer = Timer.new()
@onready var ball: CPUParticles2D

@export var flame = false
var fade = false
var fading_out = false

var ini_scale = scale.x
var light_range = 0.8
var speed = 0.08
var x = float(randi_range(ini_scale, (ini_scale + light_range)))

func _ready():
	ball = find_child("BALL", true, false)
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = 0.1
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _process(_delta: float) -> void:
	if flame:
		if ball != null: ball.visible = true
	else:
		if ball != null: ball.visible = false
	if fade == true:
		fade_out()
	var y = ini_scale
	
	if !fading_out:
		scale.x = lerp(y, x, speed)
		scale.y = lerp(y, x, speed)
		y = lerp(y, x, speed)

func fade_out():
	await Game.wait_for_seconds(0.5)
	fading_out = true
	while scale.x > 0:
		scale -= Vector2.ONE

func _on_timer_timeout():
	timer.start()
	x = float(randi_range(ini_scale, (ini_scale + light_range)))
