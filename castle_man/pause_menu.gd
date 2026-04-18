extends Control

@onready var restart: Button = $Restart
@onready var quit: Button = $Quit
@onready var sfx_db: HSlider = $SfxDb
@onready var music_db: HSlider = $MusicDb

var level: Node2D

func _ready():
	visible = false
	# Set slider initial values from current bus volumes
	sfx_db.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Sfx")))
	music_db.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))

	sfx_db.value_changed.connect(_on_sfx_changed)
	music_db.value_changed.connect(_on_music_changed)
	
	level = get_tree().get_nodes_in_group("LevelScene")[0]

func _on_sfx_changed(value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sfx"), linear_to_db(value))

func _on_music_changed(value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			visible = false
			level.process_mode = Node.PROCESS_MODE_INHERIT
			return
		if !visible:
			if Game.sfx_pool.size() > 0:
				Game.sfx_pool.clear()
			level.process_mode = Node.PROCESS_MODE_DISABLED
			visible = true
