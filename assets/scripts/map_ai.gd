extends Node2D

var enemy_turret = preload("res://assets/scenes/enemy_turret.tscn")
var enemy_shooter = preload("res://assets/scenes/enemy_shooter.tscn")
var enemy_fighter = preload("res://assets/scenes/enemy_fighter.tscn")
var boss = preload("res://assets/scenes/enemy_boss.tscn")
var crate = preload("res://assets/scenes/crate.tscn")
var key = preload("res://assets/scenes/key.tscn")
var health_pickup = preload("res://assets/scenes/health_pickup.tscn")
var locked_door = preload("res://assets/scenes/door.tscn")

@onready var pathfinding = $Pathfinding
@onready var enemy_container = $EnemyContainer

var placement_policies = [
	{
		"rule_name": "start room",
		"condition": func(level_manager, room): return room.is_start,
		"continue_evaluating": false,
		"spawn_objects": [],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "boss",
		"condition": func(level_manager, room): return room.is_end,
		"continue_evaluating": false,
		"spawn_objects": [
			{
				"type": boss,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.CENTER,
				"destroy_to_complete": true,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "tutorial",
		"condition": func(level_manager, room): return room.room_type == RoomType.TUTORIAL,
		"continue_evaluating": false,
		"spawn_objects": [
			{
				"type": enemy_turret,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.CENTER,
				"destroy_to_complete": true,
			}
		],
		"spawn_on_room_complete": [
			{
				"type": health_pickup,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.CENTER,
			}
		],
		"on_room_complete_callback": func(room): print("Tutorial room completed"),
	},
]

func spawn_room_objects(level_manager):
	for room in level_manager.room_container.get_children():
		for policy in placement_policies:
			if not policy["condition"].call(level_manager, room):
				continue

			print("rule=", policy["rule_name"], " applies to ", room)

			room.spawn_with_policy(level_manager, policy["spawn_objects"])
			room.set_cleared_pickup(level_manager, policy["spawn_on_room_complete"], policy["on_room_complete_callback"])

			if not policy["continue_evaluating"]:
				break

func spawn_gameplay_components():
	pass

# func spawn_boss(level_manager):
# 	var boss_spawn = boss.instantiate()
# 	add_child(boss_spawn)
# 	boss_spawn.position = level_manager.end_room.position

# func spawn_enemies(level_manager):
# 	var eligible_rooms = []

# 	# Collect eligible rooms (excluding start and end rooms)
# 	for room in room_container.get_children():
# 		if room.main_path_index == 1:
# 			tutorial_room = room
# 		if not room.is_start and not room.is_end and not room.main_path_index == 1:
# 			eligible_rooms.append(room)
	
# 	for room in eligible_rooms:
# 		var rule = determine_enemy_rule(room)
# 		spawn_enemies_in_room(room, rule)
	
# 	var turret_instance = map_ai.spawn_enemy_turret(tutorial_room.position)
# 	tutorial_room.add_child(turret_instance)

# # Function to determine which enemy rule to apply to a room
# func determine_enemy_rule(room):
# 	var rule_key = ""

# 	# Find maximum room distance index
# 	var max_distance_index = 0
# 	for current_room in room_container.get_children():
# 		if current_room.distance_index > max_distance_index:
# 			max_distance_index = current_room.distance_index

# 	if room.is_arena:
# 		if room.distance_index <= max_distance_index / 3:
# 			rule_key = "arena_easy"
# 		elif room.distance_index <= max_distance_index / 2:
# 			rule_key = "arena_moderate"
# 		else:
# 			rule_key = "arena_hard"
# 	else:
# 		if room.distance_index <= max_distance_index / 3:
# 			rule_key = "room_easy"
# 		elif room.distance_index <= max_distance_index / 2:
# 			rule_key = "room_moderate"
# 		else:
# 			rule_key = "room_hard"
	
# 	return enemy_spawn_grammar.get(rule_key, [])

# # Function to spawn enemies in a room according to the given rule
# func spawn_enemies_in_room(room, rule):
# 	for enemy_definition in rule:
# 		if randf() <= enemy_definition.probability:
# 			var enemy_type = enemy_definition.type
# 			var enemy_count = enemy_definition.get("count", 0)
# 			for i in range(enemy_count):
# 				var enemy_position = Vector2(
# 					randf_range(-room.size.x / 2, room.size.x / 2),
# 					randf_range(-room.size.y / 2, room.size.y / 2)
# 				)
# 				enemy_position += room.position
				
# 				if enemy_type == "turret":
# 					map_ai.spawn_enemy_turret(enemy_position)
# 				elif enemy_type == "shooter":
# 					map_ai.spawn_enemy_shooter(enemy_position)
# 				elif enemy_type == "fighter":
# 					map_ai.spawn_enemy_fighter(enemy_position)

# func place_gameplay_components():
# 	var main_path_rooms = []
# 	var off_path_rooms = []
# 	var leaf_node_rooms = []
	
# 	for room in room_container.get_children():
# 		if room.main_path_index != -1:
# 			main_path_rooms.append(room)
# 		else:
# 			off_path_rooms.append(room)
# 			if room.corridor_count == 1:
# 				leaf_node_rooms.append(room)
	
# 	if off_path_rooms.size() == 0 or main_path_rooms.size() <= 1:
# 		return
	
# 	var locked_door_room = null
# 	for room in main_path_rooms:
# 		if room.main_path_index == level_manager.end_room.main_path_index - 1:
# 			locked_door_room = room
# 			break
	
# 	# Place locked door in a room on the main path but not the start room
# 	var locked_door_instance = locked_door.instantiate()
# 	locked_door_room.add_child(locked_door_instance)
# 	locked_door_instance.position = Vector2(0, -locked_door_room.size.y)
	
# 	# Place key in an off-path room
# 	var key_room = leaf_node_rooms[randi() % leaf_node_rooms.size()]
# 	var key_instance = key.instantiate()
# 	key_room.add_child(key_instance)
# 	key_instance.position = Vector2(0, 0)
# 	leaf_node_rooms.erase(leaf_node_rooms.find(key_room))

# 	# Place fire rate pickup in 1 random leaf node room
# 	var firerate_pickup_room = off_path_rooms[randi() % off_path_rooms.size()]
# 	while firerate_pickup_room == key_room:
# 		firerate_pickup_room = off_path_rooms[randi() % off_path_rooms.size()]

# 	var firerate_pickup_instance = firerate_pickup.instantiate()
# 	firerate_pickup_room.add_child(firerate_pickup_instance)

# 	var firerate_pickup_position = Vector2(
# 		randf_range(-firerate_pickup_room.size.x / 2, firerate_pickup_room.size.x / 2),
# 		randf_range(-firerate_pickup_room.size.y / 2, firerate_pickup_room.size.y / 2)
# 	)

# 	firerate_pickup_instance.position = firerate_pickup_position
# 	off_path_rooms.erase(off_path_rooms.find(firerate_pickup_room))

# 	# Place swift boots in 1 random leaf node room
# 	var swift_boots_room = off_path_rooms[randi() % off_path_rooms.size()]
# 	while swift_boots_room == key_room || swift_boots_room == firerate_pickup_room:
# 		swift_boots_room = off_path_rooms[randi() % off_path_rooms.size()]
# 	var swift_boots_instance = swift_boots.instantiate()
# 	swift_boots_room.add_child(swift_boots_instance)

# 	var swift_boots_position = Vector2(
# 		randf_range(-swift_boots_room.size.x / 2, swift_boots_room.size.x / 2),
# 		randf_range(-swift_boots_room.size.y / 2, swift_boots_room.size.y / 2)
# 	)

# 	swift_boots_instance.position = swift_boots_position
# 	off_path_rooms.erase(off_path_rooms.find(swift_boots_room))
	
# 	# Place crates in 10 random rooms
# 	for i in range(10):
# 		var crate_room = off_path_rooms[randi() % off_path_rooms.size()]
		
# 		var crate_position = Vector2(
# 			randf_range(-crate_room.size.x / 2, crate_room.size.x / 2),
# 			randf_range(-crate_room.size.y / 2, crate_room.size.y / 2)
# 		)
		
# 		var crate_instance = crate.instantiate()
# 		crate_room.add_child(crate_instance)
# 		crate_instance.position = crate_position

# func spawn_enemy_shooter(spawn_location: Vector2):
# 	var shooter_instance = enemy_shooter.instantiate()
# 	shooter_instance.global_position = spawn_location
# 	enemy_container.add_child(shooter_instance)

# func spawn_enemy_turret(spawn_location: Vector2):
# 	var turret_instance = enemy_turret.instantiate()
# 	turret_instance.global_position = spawn_location
# 	enemy_container.add_child(turret_instance)

# func spawn_enemy_fighter(spawn_location: Vector2):
# 	var fighter_instance = enemy_fighter.instantiate()
# 	fighter_instance.global_position = spawn_location
# 	enemy_container.add_child(fighter_instance)
