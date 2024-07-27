extends Node

@onready var loading_screen_scene = preload("res://assets/scenes/loading_screen.tscn")

var scene_to_load_path = ""
var loading_screen_scene_instance = null
var scene_instance = null
var loading = false

func load_scene(scene_path):
	var current_scene = get_tree().get_current_scene()

	loading_screen_scene_instance = loading_screen_scene.instantiate()
	get_tree().root.call_deferred("add_child", loading_screen_scene_instance)

	if ResourceLoader.has_cached(scene_path):
		ResourceLoader.load_threaded_get(scene_path)
	else:
		ResourceLoader.load_threaded_request(scene_path)
	
	current_scene.queue_free()

	loading = true
	scene_file_path = scene_path

func _process(delta):
	if not loading:
		return

	var progress = []
	var status = ResourceLoader.load_threaded_get_status(scene_file_path, progress)

	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		var progress_bar = loading_screen_scene_instance.get_node("PanelContainer/MarginContainer/ProgressBar")
		progress_bar.value = progress[0] * 100
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(scene_file_path))
		loading_screen_scene_instance.queue_free()
		loading = false
	else:
		print("Error loading scene: " + scene_file_path)
		loading_screen_scene_instance.queue_free()
		loading = false

func _on_scene_load_complete():
	get_tree().change_scene_to_packed(scene_instance)
	loading_screen_scene_instance.queue_free()
	loading = false
