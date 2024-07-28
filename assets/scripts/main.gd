extends Node2D

var player = preload("res://assets/scenes/player.tscn")
var level_exit = preload("res://assets/scenes/level_exit.tscn")

@onready var level_manager = $Level
@onready var map_ai = $MapAI
@onready var tilemap = $TileMap
@onready var pathfinding = $Pathfinding
@onready var gui = $GUI

@onready var room_container = $Level/Rooms
@onready var corridor_container = $Level/Corridors

var player_instance = null
var debug_mode = false
var tutorial_room = null

func _ready():
	randomize()

	await level_manager.load_complete

	pathfinding.create_navigation_map(tilemap)

	spawn_player()
	map_ai.spawn_room_objects(self)

func _draw():
	queue_redraw()

func _input(event):
	if event.is_action_pressed("ui_select"):
		if debug_mode:
			level_manager.clear_map()
			if !debug_mode:
				debug_mode = true
				$Camera2D.enabled = true
			level_manager.make_rooms()
		#else:
			#make_level()
	
	if event.is_action_pressed("ui_focus_next"):
		if debug_mode:
			level_manager.generate_tiles()
	
	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()
	
	if event.is_action_pressed("change_camera"):
		$Camera2D.enabled = !$Camera2D.enabled
		var player_camera = player_instance.get_node("Player").get_node("Camera2D")
		player_camera.enabled = !player_camera.enabled

func spawn_player():
	player_instance = player.instantiate()
	add_child(player_instance)
	player_instance.position = Vector2(
		level_manager.start_room.position.x, 
		level_manager.start_room.position.y - (level_manager.start_room.size[1] / 4))
	debug_mode = false
	$Camera2D.enabled = false
	gui.set_player(player_instance.get_node("Player"))

func exit_reached():
	level_manager.make_level(tilemap)
