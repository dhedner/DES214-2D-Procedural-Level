extends Area2D

func _on_body_entered(body):
	if body.name == "Player":
		body.pick_up_fire_rate()
		queue_free()

func _process(delta):
	queue_redraw()
