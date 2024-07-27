extends CanvasLayer

func _on_start_button_pressed():
	SceneLoader.load_scene("res://assets/scenes/main.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
