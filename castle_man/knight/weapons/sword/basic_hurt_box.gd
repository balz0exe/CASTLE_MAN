extends Area2D

var parent

func _ready() -> void:
	parent = get_parent()
	connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if (body.is_in_group("player") or body.is_in_group("enemies")) and body != parent.from:
		body.take_damage(parent.throw_damage, self)
