extends Area2D

func _on_body_entered(body):
	var name = body.name
	if body.name == "Player":
		body.pick_up_key()
		queue_free()

#func _draw():
	#var parent_position = position
	#draw_circle(parent_position, 56, Color(1, 1, 0, 0.5))

func _process(delta):
	queue_redraw()
