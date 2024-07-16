extends Node2D

var player = preload("res://assets/scenes/player.tscn")
var level_exit = preload("res://assets/scenes/level_exit.tscn")

@onready var level_manager = $Level
@onready var map_ai = $MapAI
@onready var tilemap = $TileMap
@onready var pathfinding = $Pathfinding

var debug_mode = false

func _ready():
	randomize()
	connect("level_exit_reached", exit_reached)

	level_manager.reset_level(tilemap)
	await get_tree().create_timer(1.1).timeout
	pathfinding.create_navigation_map(tilemap)
	map_ai.initialize(pathfinding)
	
	map_ai.spawn_enemy_shooter(Vector2(516, 0))
	spawn_player()

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
			#reset_level()
	
	if event.is_action_pressed("ui_focus_next"):
		if debug_mode:
			level_manager.generate_tiles()
	
	if event.is_action_pressed("reset"):
		level_manager.reset_level()
		pass
	
	if event.is_action_pressed("change_camera"):
		pass

func spawn_player():
	var player_spawn = player.instantiate()
	add_child(player_spawn)
	player_spawn.position = Vector2(
		level_manager.start_room.position.x, 
		level_manager.start_room.position.y - (level_manager.start_room.size[1] / 4))
	debug_mode = false
	$Camera2D.enabled = false

func exit_reached():
	level_manager.reset_level(tilemap)

#func spawn_enemy():
	#var eligible_rooms = []
#
	#for room in $Rooms.get_children():
		#if not room.is_start and not room.is_end:
			#eligible_rooms.append(room)
	#
	#for i in range(10):
		#var chosen_room = eligible_rooms[randi() % eligible_rooms.size()]
		##var enemy_instance = enemy.instantiate()
#
		## Random position within the room
		#var enemy_position = Vector2(
			#randf_range(-chosen_room.size.x / 2, chosen_room.size.x / 2),
			#randf_range(-chosen_room.size.y / 2, chosen_room.size.y / 2)
		#)

		#chosen_room.add_child(enemy_instance)
		#enemy_instance.position = enemy_position
		#print("Spawned enemy at: ", enemy_position, " in room: ", chosen_room)


func place_gameplay_components():
	pass
	#var main_path_rooms = []
	#var off_path_rooms = []
	#var leaf_node_rooms = []
	#
	#for room in $Rooms.get_children():
		#var connections = path.get_point_connections(room.graph_id)
		#if room.main_path_index != -1:
			#main_path_rooms.append(room)
		#else:
			#off_path_rooms.append(room)
			#if connections.size() == 1 and not room.is_start and not room.is_end:
				#leaf_node_rooms.append(room)
	#
	#if off_path_rooms.size() == 0 or main_path_rooms.size() <= 1:
		#return
	#
	#var end_room_index = end_room.main_path_index
	#var locked_door_room = null
	#for room in main_path_rooms:
		#if room.main_path_index == end_room_index - 1:
			#locked_door_room = room
			#break
	#
	## Place locked door in a room on the main path but not the start room
	#var locked_door_instance = locked_door.instantiate()
	#locked_door_room.add_child(locked_door_instance)
	#locked_door_instance.position = Vector2(0, 0)
	#
	## Place key in an off-path room
	#var key_room = leaf_node_rooms[randi() % leaf_node_rooms.size()]
	#var key_instance = key.instantiate()
	#key_room.add_child(key_instance)
	#key_instance.position = Vector2(0, 0)
#
	## Place powerup in 3 random rooms
	#for i in range(3):
		#var powerup_room = off_path_rooms[randi() % off_path_rooms.size()]
		#
		#var powerup_position = Vector2(
			#randf_range(-powerup_room.size.x / 2, powerup_room.size.x / 2),
			#randf_range(-powerup_room.size.y / 2, powerup_room.size.y / 2)
		#)
		#
		#var powerup_instance = powerup.instantiate()
		#powerup_room.add_child(powerup_instance)
		#powerup_instance.position = powerup_position
#
	## Place health pickup in 3 random rooms
	#for i in range(3):
		#var health_pickup_room = off_path_rooms[randi() % off_path_rooms.size()]
		#
		#var health_pickup_position = Vector2(
			#randf_range(-health_pickup_room.size.x / 2, health_pickup_room.size.x / 2),
			#randf_range(-health_pickup_room.size.y / 2, health_pickup_room.size.y / 2)
		#)
		#
		#var health_pickup_instance = health_pickup.instantiate()
		#health_pickup_room.add_child(health_pickup_instance)
		#health_pickup_instance.position = health_pickup_position
