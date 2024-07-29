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
var spike = preload("res://assets/scenes/spike.tscn")
var spike_group = preload("res://assets/scenes/spike_group.tscn")
var key = preload("res://assets/scenes/key.tscn")
var health_pickup = preload("res://assets/scenes/health_pickup.tscn")
var locked_door = preload("res://assets/scenes/door.tscn")
var heart_container = preload("res://assets/scenes/heart_container.tscn")
var firerate_pickup = preload("res://assets/scenes/firerate_pickup.tscn")
var swift_boots = preload("res://assets/scenes/swift_boots.tscn")

@onready var enemy_container = $EnemyContainer

# Temporary tracking for objects like keys
var used_key_count = 0
var treasures = []

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
				"placement": PlacementType.GRID_2X2_CENTERED,
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
				"placement": PlacementType.GRID_2X2_CENTERED,
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
				"placement": PlacementType.GRID_2X2_CENTERED,
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
				"placement": PlacementType.GRID_2X2_CENTERED,
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
				"placement": PlacementType.GRID_2X2_CENTERED,
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
				"placement": PlacementType.GRID_2X2_CENTERED,
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
				"count": func(level_manager, room): return 4,
				"placement": PlacementType.GRID_2X2_CENTERED,
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
				"count": func(level_manager, room): return 4,
				"placement": PlacementType.ALL_FLOOR_GRID_4X4_SPACING,
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
				"count": func(level_manager, room): return 4,
				"placement": PlacementType.GRID_2X2_CENTERED,
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
		"rule_name": "treasure_room_last_resort",
		"condition": func(level_manager, room): return room.is_leading_to_end and len(treasures) > 0,
		"continue_evaluating": true,
		"spawn_objects": [
			{
				"type": func(level_manager, room): return treasures,
				"placement": PlacementType.CENTER,
				"destroy_to_complete": false,
			},
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "easy_standard_room_object_group_type_1",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score < 0.33 and randf() < 0.5,
		"continue_evaluating": true,
		"spawn_objects": [
			{
				"type": wall_torch,
				"count": func(level_manager, room): return 1000000,
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
				"placement": PlacementType.GRID_2X2_CENTERED,
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
		"continue_evaluating": false,
		"spawn_objects": [
			{
				"type": spike,
				"count": func(level_manager, room): return 4,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": false,
			},
			{
				"type": wall_torch,
				"count": func(level_manager, room): return 1000000,
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
		"continue_evaluating": false,
		"spawn_objects": [
			{
				"type": spike_group,
				"count": func(level_manager, room): return 4,
				"placement": PlacementType.GRID_2X2_CENTERED,
				"destroy_to_complete": false,
			},
			{
				"type": spike,
				"count": func(level_manager, room): return 2,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": false,
			},
			{
				"type": ground_torch,
				"count": func(level_manager, room): return 2,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": false,
			},
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "hard_standard_room_object_group_type_1",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score > 0.66 and randf() < 0.4,
		"continue_evaluating": false,
		"spawn_objects": [
			{
				"type": spike_group,
				"count": func(level_manager, room): return 4,
				"placement": PlacementType.ALL_FLOOR_GRID_4X4_SPACING,
				"destroy_to_complete": false,
			},
			{
				"type": spike,
				"count": func(level_manager, room): return 2,
				"placement": PlacementType.RANDOM,
				"destroy_to_complete": false,
			},
			{
				"type": wall_torch,
				"count": func(level_manager, room): return 1000000,
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
		"continue_evaluating": false,
		"spawn_objects": [
			{
				"type": spike_group,
				"count": func(level_manager, room): return 6,
				"placement": PlacementType.ALL_FLOOR_GRID_3X3_SPACING,
				"destroy_to_complete": false,
			},
			{
				"type": ground_torch,
				"count": func(level_manager, room): return 2,
				"placement": PlacementType.GRID_2X2_CENTERED,
				"destroy_to_complete": false,
			},
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "hard_standard_room_object_group_type_3",
		"condition": func(level_manager, room): 
			return (room.room_type == RoomType.ON_MAIN_PATH or room.room_type == RoomType.OFF_MAIN_PATH) and room.distance_score > 0.66 and randf() < 0.4,
		"continue_evaluating": false,
		"spawn_objects": [
			{
				"type": ground_torch,
				"count": func(level_manager, room): return 2,
				"placement": PlacementType.GRID_2X2_CENTERED,
				"destroy_to_complete": false,
			},
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
	{
		"rule_name": "treasure_room",
		"condition": func(level_manager, room): 
			return len(treasures) > 0 and room.room_type == RoomType.TREASURE,
		"continue_evaluating": true,
		"spawn_objects": [
			{
				"type": func(level_manager, room): return [treasures.pop_front()],
				"count": func(level_manager, room): return 1,
				"placement": PlacementType.CENTER,
				"destroy_to_complete": false,
			},
		],
		"spawn_on_room_complete": [],
		"on_room_complete_callback": func(room): pass,
	},
]

func spawn_room_objects(level_manager, room_container):
	treasures = [
		firerate_pickup,
		swift_boots,
		key
	]

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
