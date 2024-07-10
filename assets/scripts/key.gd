extends Area2D

func _on_body_entered(body):
	if body.name == "player":
		body.pick_up_key()
		queue_free()

func _draw():
	var parent_position = get_parent().position
	draw_circle(parent_position, 56, Color(1, 1, 0, 0.5))

func _process(delta):
	queue_redraw()
