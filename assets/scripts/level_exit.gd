extends Area2D

signal level_exit_reached()

func _on_body_entered(body):
	var name = body.name
	if body.name == "Player":
		emit_signal("level_exit_reached")
