extends Area2D

var player

func _ready() -> void:
	player = get_parent()

func _on_area_entered(area: Node2D) -> void:
	if !player.dead:
		if area.get_parent().is_in_group("enemies") and player.velocity.y > 0:
			if Input.is_action_pressed("ui_down"):
				bounce()
				area.get_parent().disarm()
				if player.damage_on_bounce:
					area.get_parent().take_damage(player.bounce_damage, player)
			else:
				var enemy = area.get_parent()
				player.take_damage(enemy.damage_factor * 4, enemy)
				player.velocity.y = player.jump_strength/ 4

func bounce():
	Game.play_sfx(player.bounce_sfx, Game.sfx_volume, player)
	Game.play_sfx(load("res://fx/audio_fx/player_landing.wav"), Game.sfx_volume + 3, player)
	player.velocity.y = player.jump_strength
