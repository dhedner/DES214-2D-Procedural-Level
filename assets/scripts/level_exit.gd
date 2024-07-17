extends Area2D

signal level_exit_reached()

func _on_body_entered(body):
	var name = body.name
	if body.name == "Player":
		if body.has_method("reset_current_scene"):
			body.reset_current_scene()
