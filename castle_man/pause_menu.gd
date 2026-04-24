extends Control

@onready var restart: Button = $Restart
@onready var quit: Button = $Quit
@onready var sfx_db: HSlider = $SfxDb
@onready var music_db: HSlider = $MusicDb

func _ready():
	visible = false
	sfx_db.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Sfx")))
	music_db.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	sfx_db.value_changed.connect(_on_sfx_changed)
	music_db.value_changed.connect(_on_music_changed)
	restart.button_up.connect(_on_restart_pressed)
	quit.button_up.connect(_on_quit_pressed)

func _on_sfx_changed(value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sfx"), linear_to_db(value))

func _on_music_changed(value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

func _on_restart_pressed():
	Game.get_level().process_mode = Node.PROCESS_MODE_INHERIT
	visible = false
	Game.go_to_scene(load("res://world/levels/title_screen.tscn"))

func _on_quit_pressed():
	get_tree().quit()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var level = Game.get_level()
		if visible:
			visible = false
			level.process_mode = Node.PROCESS_MODE_INHERIT
			if Game.get_game_handler() != null:
				Game.get_game_handler().process_mode = Node.PROCESS_MODE_INHERIT
		else:
			level.process_mode = Node.PROCESS_MODE_DISABLED
			if Game.get_game_handler() != null:
				Game.get_game_handler().process_mode = Node.PROCESS_MODE_DISABLED
			visible = true
