extends Node2D

var player = preload("res://assets/scenes/player.tscn")
var boss = preload("res://assets/scenes/enemy_boss.tscn")
var level_exit = preload("res://assets/scenes/level_exit.tscn")
var locked_door = preload("res://assets/scenes/door.tscn")
var key = preload("res://assets/scenes/key.tscn")
var firerate_pickup = preload("res://assets/scenes/firerate_pickup.tscn")
var health_pickup = preload("res://assets/scenes/health_pickup.tscn")
var heart_container = preload("res://assets/scenes/heart_container.tscn")
var swift_boots = preload("res://assets/scenes/swift_boots.tscn")
var crate = preload("res://assets/scenes/crate.tscn")

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

var enemy_spawn_grammar = {
	"arena_easy": [
		{"type": "turret", "count": 2, "probability": 1.0},
		{"type": "shooter", "count": 1, "probability": 1.0},
	],
	"arena_moderate": [
		{"type": "turret", "count": 2, "probability": 0.7},
		{"type": "shooter", "count": 1, "probability": 0.8},
		{"type": "fighter", "count": 2, "probability": 0.6},
	],
	"arena_hard": [
		{"type": "turret", "count": 3, "probability": 0.8},
		{"type": "shooter", "count": 2, "probability": 0.8},
		{"type": "fighter", "count": 2, "probability": 0.8},
	],
	"room_easy": [
		{"type": "turret", "count": 1, "probability": 0.4},
		{"type": "shooter", "count": 1, "probability": 0.4},
		{"type": "empty", "probability": 0.2}
	],
	"room_moderate": [
		{"type": "turret", "count": 1, "probability": 0.3},
		{"type": "shooter", "count": 1, "probability": 0.3},
		{"type": "fighter", "count": 1, "probability": 0.4},
		{"type": "empty", "probability": 0.1}
	],
	"room_hard": [
		{"type": "shooter", "count": 2, "probability": 0.4},
		{"type": "fighter", "count": 1, "probability": 0.7},
		{"type": "empty", "probability": 0.2}
	]
}

func _ready():
	randomize()

	await level_manager.load_complete

	pathfinding.create_navigation_map(tilemap)
	map_ai.initialize(pathfinding)
	var level_exit_instance = level_exit.instantiate()
	
	spawn_player()
	spawn_enemies()
	spawn_boss()
	place_gameplay_components()
	
	var turret_position = Vector2(
		randf_range(-tutorial_room.size.x / 2, tutorial_room.size.x / 2),
		randf_range(-tutorial_room.size.y / 2, tutorial_room.size.y / 2)
	)
	
	var turret_instance = map_ai.spawn_enemy_turret(tutorial_room.position)
	tutorial_room.add_child(turret_instance)

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

func spawn_boss():
	var boss_spawn = boss.instantiate()
	add_child(boss_spawn)
	boss_spawn.position = level_manager.end_room.position

func exit_reached():
	level_manager.make_level(tilemap)

func spawn_enemies():
	var eligible_rooms = []

	# Collect eligible rooms (excluding start and end rooms)
	for room in room_container.get_children():
		if room.main_path_index == 1:
			tutorial_room = room
		if not room.is_start and not room.is_end and not room.main_path_index == 1:
			eligible_rooms.append(room)
	
	for room in eligible_rooms:
		var rule = determine_enemy_rule(room)
		spawn_enemies_in_room(room, rule)

# Function to determine which enemy rule to apply to a room
func determine_enemy_rule(room):
	var rule_key = ""

	# Find maximum room distance index
	var max_distance_index = 0
	for current_room in room_container.get_children():
		if current_room.distance_index > max_distance_index:
			max_distance_index = current_room.distance_index

	if room.is_arena:
		if room.distance_index <= max_distance_index / 3:
			rule_key = "arena_easy"
		elif room.distance_index <= max_distance_index / 2:
			rule_key = "arena_moderate"
		else:
			rule_key = "arena_hard"
	else:
		if room.distance_index <= max_distance_index / 3:
			rule_key = "room_easy"
		elif room.distance_index <= max_distance_index / 2:
			rule_key = "room_moderate"
		else:
			rule_key = "room_hard"
	
	return enemy_spawn_grammar.get(rule_key, [])

# Function to spawn enemies in a room according to the given rule
func spawn_enemies_in_room(room, rule):
	for enemy_definition in rule:
		if randf() <= enemy_definition.probability:
			var enemy_type = enemy_definition.type
			var enemy_count = enemy_definition.get("count", 0)
			for i in range(enemy_count):
				var enemy_instance = null
				var enemy_position = Vector2(
					randf_range(-room.size.x / 2, room.size.x / 2),
					randf_range(-room.size.y / 2, room.size.y / 2)
				)
				enemy_position += room.position
				
				if enemy_type == "turret":
					map_ai.spawn_enemy_turret(enemy_position)
				elif enemy_type == "shooter":
					map_ai.spawn_enemy_shooter(enemy_position)
				elif enemy_type == "fighter":
					map_ai.spawn_enemy_fighter(enemy_position)

func place_gameplay_components():
	var main_path_rooms = []
	var off_path_rooms = []
	var leaf_node_rooms = []
	
	for room in room_container.get_children():
		if room.main_path_index != -1:
			main_path_rooms.append(room)
		else:
			off_path_rooms.append(room)
			if room.corridor_count == 1:
				leaf_node_rooms.append(room)
	
	if off_path_rooms.size() == 0 or main_path_rooms.size() <= 1:
		return
	
	var locked_door_room = null
	for room in main_path_rooms:
		if room.main_path_index == level_manager.end_room.main_path_index - 1:
			locked_door_room = room
			break
	
	# Place locked door in a room on the main path but not the start room
	var locked_door_instance = locked_door.instantiate()
	locked_door_room.add_child(locked_door_instance)
	locked_door_instance.position = Vector2(0, -locked_door_room.size.y)
	
	# Place key in an off-path room
	var key_room = leaf_node_rooms[randi() % leaf_node_rooms.size()]
	var key_instance = key.instantiate()
	key_room.add_child(key_instance)
	key_instance.position = Vector2(0, 0)
	leaf_node_rooms.erase(leaf_node_rooms.find(key_room))

	# Place fire rate pickup in 1 random leaf node room
	var firerate_pickup_room = off_path_rooms[randi() % off_path_rooms.size()]
	while firerate_pickup_room == key_room:
		firerate_pickup_room = off_path_rooms[randi() % off_path_rooms.size()]

	var firerate_pickup_instance = firerate_pickup.instantiate()
	firerate_pickup_room.add_child(firerate_pickup_instance)

	var firerate_pickup_position = Vector2(
		randf_range(-firerate_pickup_room.size.x / 2, firerate_pickup_room.size.x / 2),
		randf_range(-firerate_pickup_room.size.y / 2, firerate_pickup_room.size.y / 2)
	)

	firerate_pickup_instance.position = firerate_pickup_position
	off_path_rooms.erase(off_path_rooms.find(firerate_pickup_room))

	# Place swift boots in 1 random leaf node room
	var swift_boots_room = off_path_rooms[randi() % off_path_rooms.size()]
	while swift_boots_room == key_room || swift_boots_room == firerate_pickup_room:
		swift_boots_room = off_path_rooms[randi() % off_path_rooms.size()]
	var swift_boots_instance = swift_boots.instantiate()
	swift_boots_room.add_child(swift_boots_instance)

	var swift_boots_position = Vector2(
		randf_range(-swift_boots_room.size.x / 2, swift_boots_room.size.x / 2),
		randf_range(-swift_boots_room.size.y / 2, swift_boots_room.size.y / 2)
	)

	swift_boots_instance.position = swift_boots_position
	off_path_rooms.erase(off_path_rooms.find(swift_boots_room))
	
	# Place crates in 10 random rooms
	for i in range(10):
		var crate_room = off_path_rooms[randi() % off_path_rooms.size()]
		
		var crate_position = Vector2(
			randf_range(-crate_room.size.x / 2, crate_room.size.x / 2),
			randf_range(-crate_room.size.y / 2, crate_room.size.y / 2)
		)
		
		var crate_instance = crate.instantiate()
		crate_room.add_child(crate_instance)
		crate_instance.position = crate_position

# When an arena room is cleared, spawn a health pickup
func on_arena_cleared(room):
	var heart_container_instance = heart_container.instantiate()
	room.add_child(heart_container_instance)
	heart_container_instance.position = Vector2(0, 0)
