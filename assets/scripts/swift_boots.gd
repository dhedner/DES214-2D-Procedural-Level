extends Area2D

func _on_body_entered(body):
	if body.name == "Player":
		body.pick_up_swift_boots()
		queue_free()
