extends StaticBody2D

@export var is_locked = true

func _draw():
	var parent_position = get_parent().position
	if is_locked:
		draw_rect(Rect2(parent_position, Vector2(64, 64)), Color(1, 0, 0, 0.5))
	else:
		draw_rect(Rect2(parent_position, Vector2(64, 64)), Color(0, 1, 0, 0.5))

func _on_body_entered(body):
	if body.name == "player" and not is_locked:
		queue_free()

func unlock():
	is_locked = false
	$CollisionShape2D.disabled = true

func _process(delta):
	queue_redraw()
