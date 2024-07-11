extends Area2D

func _on_body_entered(body):
	if body.name == "Player":
		body.pick_up_health()
		queue_free()

#func _draw():
	#var parent_position = position
	#draw_circle(parent_position, 56, Color(1, 0.5, 0.5, 0.5))

#func _process(delta):
	#queue_redraw()
