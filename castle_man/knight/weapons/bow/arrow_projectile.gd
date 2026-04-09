extends Projectile


func _on_area_2d_r_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") or body.is_in_group("player"):
		queue_free()

func _on_area_2d_l_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") or body.is_in_group("player"):
		queue_free()
