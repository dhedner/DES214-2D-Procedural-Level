extends Node2D

@onready var level_manager = $Level

var room = preload("res://assets/scenes/room.tscn")
var corridor = preload("res://assets/scenes/corridor.tscn")
var player = preload("res://assets/scenes/player.tscn")
var enemy = preload("res://assets/scenes/enemy.tscn")
var locked_door = preload("res://assets/scenes/door.tscn")
var key = preload("res://assets/scenes/key.tscn")
var powerup = preload("res://assets/scenes/powerup.tscn")
var health_pickup = preload("res://assets/scenes/health_pickup.tscn")

var debug_mode = true

#var player_spawn = null
#var enemies = []

func _ready():
	randomize()
	if debug_mode:
		await level_manager.make_rooms()
	#else:
		#reset_level()

#func _draw():
	#if !debug_mode:
		#return

#func _process(delta):
	#queue_redraw()

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
	
	#if event.is_action_pressed("ui_cancel"):
		#player_spawn = player.instantiate()
		#add_child(player_spawn)
		#player_spawn.position = Vector2(start_room.position.x, start_room.position.y + (start_room.size[1]))
		#debug_mode = false
		#$Camera2D.enabled = false
	
	if event.is_action_pressed("reset"):
		#reset_level()
		pass
	
	if event.is_action_pressed("change_camera"):
		pass

func spawn_player():
	var player_spawn = player.instantiate()
	add_child(player_spawn)
	#player_spawn.position = Vector2(start_room.position.x, start_room.position.y - (start_room.size[1] / 4))
	debug_mode = false
	$Camera2D.enabled = false

func spawn_enemy():
	var eligible_rooms = []

	for room in $Rooms.get_children():
		if not room.is_start and not room.is_end:
			eligible_rooms.append(room)
	
	for i in range(10):
		var chosen_room = eligible_rooms[randi() % eligible_rooms.size()]
		var enemy_instance = enemy.instantiate()

		# Random position within the room
		var enemy_position = Vector2(
			randf_range(-chosen_room.size.x / 2, chosen_room.size.x / 2),
			randf_range(-chosen_room.size.y / 2, chosen_room.size.y / 2)
		)

		chosen_room.add_child(enemy_instance)
		enemy_instance.position = enemy_position
		print("Spawned enemy at: ", enemy_position, " in room: ", chosen_room)


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
