extends Node2D

var enemy_tutorial = preload("res://assets/scenes/enemy_tutorial.tscn")
var enemy_turret = preload("res://assets/scenes/enemy_turret.tscn")
var enemy_shooter = preload("res://assets/scenes/enemy_shooter.tscn")
var enemy_fighter = preload("res://assets/scenes/enemy_fighter.tscn")
var enemy_tank = preload("res://assets/scenes/enemy_tank.tscn")
var boss = preload("res://assets/scenes/enemy_boss.tscn")
var crate = preload("res://assets/scenes/crate.tscn")
var wall_torch = preload("res://assets/scenes/wall_torch.tscn")
var ground_torch = preload("res://assets/scenes/ground_torch.tscn")
var spikes = preload("res://assets/scenes/spikes.tscn")
var key = preload("res://assets/scenes/key.tscn")
var health_pickup = preload("res://assets/scenes/health_pickup.tscn")
var locked_door = preload("res://assets/scenes/door.tscn")
var heart_container = preload("res://assets/scenes/heart_container.tscn")
var firerate_pickup = preload("res://assets/scenes/firerate_pickup.tscn")
var swift_boots = preload("res://assets/scenes/swift_boots.tscn")

@onready var pathfinding = $Pathfinding
@onready var enemy_container = $EnemyContainer

# Temporary tracking for objects like keys
var used_key_count = 0
var treasures = [
	firerate_pickup,
	swift_boots,
	key
]

var terrain_spawn_policies = [
	{
		"rule_name": "pits",
		"condition": func(level_manager, room): 
			return not room.is_cramped and not room.is_elongated and not room.corner_rect and (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and randf() < level_manager.pit_probability,
		"continue_evaluating": false,
		"spawn_terrain": [
			{
				"layer": 2,
				"terrain": 3,
				"count": func(level_manager, room): return 9,
				"placement": PlacementType.CENTER,
				"is_blocking_tiles": true,
			}
		]
	}
]

var enemy_spawn_policies = [
	{
		"rule_name": "boss_enemy",
		"condition": func(level_manager, room): return room.is_end,
		"continue_evaluating": false,
		"spawn_enemies": [
			{
				"type": boss,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.CENTER,
				"destroy_to_complete": true,
			},
			{
				"type": locked_door,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.DOORS,
				"destroy_to_complete": false,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "tutorial_enemy",
		"condition": func(level_manager, room): return room.room_type == RoomType.TUTORIAL,
		"continue_evaluating": false,
		"spawn_enemies": [
			{
				"type": enemy_tutorial,
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
	{
		"rule_name": "easy_standard_room_enemy_group_type_1",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score < 0.33 and randf() < 0.4,
		"continue_evaluating": false,
		"spawn_enemies": [
			{
				"type": enemy_turret,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.CENTER,
				"destroy_to_complete": true,
			},
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "easy_standard_room_enemy_group_type_2",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score < 0.33 and randf() < 0.3,
		"continue_evaluating": false,
		"spawn_enemies": [
			{
				"type": enemy_turret,
				"count": func(level_manager, room): return 2,
				"placement": PlacementType.ALL_FLOOR_GRID_3X3_SPACING,
				"destroy_to_complete": true,
			},
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "medium_standard_room_enemy_group_type_1",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score < 0.66 and room.distance_score > 0.33 and randf() < 0.3,
		"continue_evaluating": false,
		"spawn_enemies": [
			{
				"type": enemy_shooter,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": true,
			},
			{
				"type": enemy_fighter,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": true,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "medium_standard_room_enemy_group_type_2",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score < 0.66 and room.distance_score > 0.33 and randf() < 0.3,
		"continue_evaluating": false,
		"spawn_enemies": [
			{
				"type": enemy_turret,
				"count": func(level_manager, room): return 2,
				"placement": PlacementType.ALL_FLOOR_GRID_3X3_SPACING,
				"destroy_to_complete": true,
			},
			{
				"type": enemy_tank,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.CENTER,
				"destroy_to_complete": true,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "medium_standard_room_enemy_group_type_3",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score < 0.66 and room.distance_score > 0.33 and randf() < 0.3,
		"continue_evaluating": false,
		"spawn_enemies": [
			{
				"type": enemy_turret,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.ALL_FLOOR_GRID_3X3_SPACING,
				"destroy_to_complete": true,
			},
			{
				"type": enemy_fighter,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.CENTER,
				"destroy_to_complete": true,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "medium_standard_room_enemy_group_type_4",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score < 0.66 and room.distance_score > 0.33,
		"continue_evaluating": false,
		"spawn_enemies": [
			{
				"type": enemy_shooter,
				"count": func(level_manager, room): return 2,
				"placement": PlacementType.ALL_FLOOR_GRID_3X3_SPACING,
				"destroy_to_complete": true,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "hard_standard_room_enemy_group_type_1",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score > 0.66 and randf() < 0.3,
		"continue_evaluating": false,
		"spawn_enemies": [
			{
				"type": enemy_shooter,
				"count": func(level_manager, room): return 2,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": true,
			},
			{
				"type": enemy_fighter,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": true,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "hard_standard_room_enemy_group_type_2",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score > 0.66 and randf() < 0.3,
		"continue_evaluating": false,
		"spawn_enemies": [
			{
				"type": enemy_shooter,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.CENTER,
				"destroy_to_complete": true,
			},
			{
				"type": enemy_tank,
				"count": func(level_manager, room): return 2,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": true,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "hard_standard_room_enemy_group_type_3",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score > 0.66 and randf() < 0.3,
		"continue_evaluating": false,
		"spawn_enemies": [
			{
				"type": enemy_shooter,
				"count": func(level_manager, room): return 2,
				"placement": PlacementType.ALL_FLOOR_GRID_3X3_SPACING,
				"destroy_to_complete": true,
			},
			{
				"type": enemy_fighter,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": true,
			},
			{
				"type": enemy_tank,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": true,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "hard_standard_room_enemy_group_type_4",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score > 0.66,
		"continue_evaluating": false,
		"spawn_enemies": [
			{
				"type": enemy_shooter,
				"count": func(level_manager, room): return 3,
				"placement": PlacementType.ALL_FLOOR_GRID_3X3_SPACING,
				"destroy_to_complete": true,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "easy_arena_room_enemy_group_type_1",
		"condition": func(level_manager, room): 
			return room.is_arena and room.distance_score < 0.33 and randf() < 0.5,
		"continue_evaluating": true,
		"spawn_enemies": [
			{
				"type": enemy_shooter,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.CENTER,
				"destroy_to_complete": true,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "easy_arena_room_enemy_group_type_2",
		"condition": func(level_manager, room): 
			return room.is_arena and room.distance_score < 0.33,
		"continue_evaluating": false,
		"spawn_enemies": [
			{
				"type": enemy_turret,
				"count": func(level_manager, room): return 3,
				"placement": PlacementType.ALL_FLOOR_GRID_3X3_SPACING,
				"destroy_to_complete": true,
			}
		],
		"spawn_on_room_complete": [
			{
				"type": heart_container,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.CENTER,
			}
		],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "medium_arena_room_enemy_group_type_1",
		"condition": func(level_manager, room): 
			return room.is_arena and room.distance_score < 0.66 and room.distance_score > 0.33 and randf() < 0.3,
		"continue_evaluating": true,
		"spawn_enemies": [
			{
				"type": enemy_tank,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": true,
			},
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "medium_arena_room_enemy_group_type_2",
		"condition": func(level_manager, room): 
			return room.is_arena and room.distance_score < 0.66 and room.distance_score > 0.33 and randf() < 0.7,
		"continue_evaluating": true,
		"spawn_enemies": [
			{
				"type": enemy_fighter,
				"count": func(level_manager, room): return 2,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": true,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "medium_arena_room_enemy_group_type_3",
		"condition": func(level_manager, room): 
			return room.is_arena and room.distance_score < 0.66 and room.distance_score > 0.33,
		"continue_evaluating": true,
		"spawn_enemies": [
			{
				"type": enemy_turret,
				"count": func(level_manager, room): return 3,
				"placement": PlacementType.ALL_FLOOR_GRID_3X3_SPACING,
				"destroy_to_complete": true,
			}
		],
		"spawn_on_room_complete": [
			{
				"type": heart_container,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.CENTER,
			}
		],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "hard_arena_room_enemy_group_type_1",
		"condition": func(level_manager, room): 
			return room.is_arena and room.distance_score > 0.66 and randf() < 0.5,
		"continue_evaluating": true,
		"spawn_enemies": [
			{
				"type": enemy_tank,
				"count": func(level_manager, room): return 2,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": true,
			},
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "hard_arena_room_enemy_group_type_2",
		"condition": func(level_manager, room): 
			return room.is_arena and room.distance_score > 0.66 and randf() < 0.7,
		"continue_evaluating": true,
		"spawn_enemies": [
			{
				"type": enemy_shooter,
				"count": func(level_manager, room): return 3,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": true,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "hard_arena_room_enemy_group_type_3",
		"condition": func(level_manager, room): 
			return room.is_arena and room.distance_score > 0.66,
		"continue_evaluating": true,
		"spawn_enemies": [
			{
				"type": enemy_turret,
				"count": func(level_manager, room): return 3,
				"placement": PlacementType.ALL_FLOOR_GRID_3X3_SPACING,
				"destroy_to_complete": true,
			}
		],
		"spawn_on_room_complete": [
			{
				"type": heart_container,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.CENTER,
			}
		],
		"on_room_complete_callback": func(room): pass,
	},
]

var object_spawn_policies = [
	{
		"rule_name": "easy_standard_room_object_group_type_1",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score < 0.33 and randf() < 0.5,
		"continue_evaluating": true,
		"spawn_objects": [
			{
				"type": wall_torch,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.NORTH_WALL,
				"destroy_to_complete": false,
			},
			{
				"type": crate,
				"count": func(level_manager, room): return 2,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": false,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "easy_standard_room_object_group_type_2",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score < 0.33 and randf() < 0.5,
		"continue_evaluating": false,
		"spawn_objects": [
			{
				"type": ground_torch,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.ALL_FLOOR_GRID_3X3_SPACING,
				"destroy_to_complete": false,
			},
			{
				"type": crate,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": false,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "medium_standard_room_object_group_type_1",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score < 0.66 and room.distance_score > 0.33 and randf() < 0.4,
		"continue_evaluating": true,
		"spawn_objects": [
			{
				"type": wall_torch,
				"count": func(level_manager, room): return 2,
				"placement": PlacementType.NORTH_WALL,
				"destroy_to_complete": false,
			},
			{
				"type": crate,
				"count": func(level_manager, room): return 3,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": false,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "medium_standard_room_object_group_type_2",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score < 0.66 and room.distance_score > 0.33 and randf() < 0.4,
		"continue_evaluating": true,
		"spawn_objects": [
			{
				"type": ground_torch,
				"count": func(level_manager, room): return 2,
				"placement": PlacementType.NORTH_WALL,
				"destroy_to_complete": false,
			},
			{
				"type": crate,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": false,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "hard_standard_room_object_group_type_1",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score > 0.66 and randf() < 0.4,
		"continue_evaluating": true,
		"spawn_objects": [
			{
				"type": wall_torch,
				"count": func(level_manager, room): return 2,
				"placement": PlacementType.NORTH_WALL,
				"destroy_to_complete": false,
			},
			{
				"type": crate,
				"count": func(level_manager, room): return 3,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": false,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "hard_standard_room_object_group_type_2",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score > 0.66 and randf() < 0.4,
		"continue_evaluating": true,
		"spawn_objects": [
			{
				"type": ground_torch,
				"count": func(level_manager, room): return 2,
				"placement": PlacementType.NORTH_WALL,
				"destroy_to_complete": false,
			},
			{
				"type": crate,
				"count": func(level_manager, room): return 3,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": false,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "hard_standard_room_object_group_type_3",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score > 0.66 and randf() < 0.4,
		"continue_evaluating": true,
		"spawn_objects": [
			{
				"type": ground_torch,
				"count": func(level_manager, room): return 3,
				"placement": PlacementType.ALL_FLOOR_GRID_3X3_SPACING,
				"destroy_to_complete": false,
			},
			{
				"type": crate,
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": false,
			}
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	# {
	# 	"rule_name": "treasure_room",
	# 	"condition": func(level_manager, room): 
	# 		return len(treasures) > 0 and room.room_type == RoomType.TREASURE,
	# 	"continue_evaluating": true,
	# 	"spawn_objects": [
	# 		{
	# 			"type": func(level_manager, room): return treasures.pop_front(),
	# 			"count": func(level_manager, room): return 3,
	# 			"placement": PlacementType.ALL_FLOOR_GRID_3X3_SPACING,
	# 			"destroy_to_complete": false,
	# 		},
	# 	],
	# 	"spawn_on_room_complete": [],
	# 	"on_room_complete_callback": func(room): pass,
	# },
]

func spawn_room_objects(level_manager, room_container):
	# Create a sorted list of rooms by distance index
	var rooms = room_container.get_children().duplicate()
	rooms.sort_custom(func(a, b): return a.distance_index < b.distance_index)

	for room in rooms:
		for policy in terrain_spawn_policies:
			if not policy["condition"].call(level_manager, room):
				continue

			# print("terrain rule=", policy["rule_name"], " applies to ", room)

			room.add_terrain_with_policy(level_manager, policy["spawn_terrain"])

			if not policy["continue_evaluating"]:
				break
		
		for policy in enemy_spawn_policies:
			if not policy["condition"].call(level_manager, room):
				continue

			# print("spawn rule=", policy["rule_name"], " applies to ", room)

			room.spawn_with_policy(level_manager, policy["spawn_enemies"])
			room.add_cleared_pickup(level_manager, policy["spawn_on_room_complete"], policy["on_room_complete_callback"])

			if not policy["continue_evaluating"]:
				break

		for policy in object_spawn_policies:
			if not policy["condition"].call(level_manager, room):
				continue

			# print("spawn rule=", policy["rule_name"], " applies to ", room)

			room.spawn_with_policy(level_manager, policy["spawn_objects"])
			room.add_cleared_pickup(level_manager, policy["spawn_on_room_complete"], policy["on_room_complete_callback"])

			if not policy["continue_evaluating"]:
				break

		# notify the room that the pickups have been set
		room.wait_for_pickups()

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
