extends Node2D

var room = preload("res://assets/scenes/room.tscn")
var corridor = preload("res://assets/scenes/corridor.tscn")

#@onready var tilemap = $TileMap

@export var tile_size = 32
@export var num_rooms = 20
@export var min_size = 6
@export var max_size = 11
@export var x_bias = 100
@export var y_bias = 200
@export var path_cycles = 1

var path : AStar2D # Graph that contains all the rooms and their corridors
var graph_id_to_room
var debug_mode = false
var start_room = null
var end_room = null

func reset_level(tilemap: TileMap):
	clear_map(tilemap)
	await make_rooms(tilemap)
	generate_tiles(tilemap)

func clear_map(tilemap: TileMap):
	tilemap.clear()
	
	for r in $Rooms.get_children():
		r.queue_free()
	
	for c in $Corridors.get_children():
		c.queue_free()
	
	path = null
	
	

func make_rooms(tilemap: TileMap):
	generate_diverse_rooms()
	# Wait for rooms to settle via physics engine
	await get_tree().create_timer(1.1).timeout
	
	find_start_and_end_rooms()
	create_start_and_end_rooms(start_room, end_room)
	
	var full_map = Rect2()
	for room in $Rooms.get_children():
		room.freeze = true;
		var rectangle = Rect2(
			room.position - room.size, 
			room.get_node("CollisionShape2D").shape.extents * 2)
		full_map = full_map.merge(rectangle)
	
	# Generate a minimum spanning tree
	await build_graph()
	create_corridors_from_graph()
	find_main_path()
	create_cycles()
	check_room_distribution(tilemap, full_map)
	assign_distance_index()

func check_room_distribution(tilemap: TileMap, map_size):
	if ((map_size.size.x / 2) > map_size.size.y) or ((map_size.size.y / 2) > map_size.size.x):
		print("Undesirable map size: ", map_size.size)
		await reset_level(tilemap)

# Change to use various layers of the same tile map (0 for floor)
func generate_tiles(tilemap: TileMap):
	tilemap.clear()
	
	if path == null:
		await get_tree().process_frame
	
	# Fill entire map with wall tiles
	var full_rect = Rect2()
	for room in $Rooms.get_children():
		var rectangle = Rect2(
			room.position - room.size, 
			room.get_node("CollisionShape2D").shape.extents * 2)
		full_rect = full_rect.merge(rectangle)
		
	var top_left = tilemap.local_to_map(full_rect.position)
	var bottom_right = tilemap.local_to_map(full_rect.end)
	for x in range (top_left.x, bottom_right.x):
		for y in range (top_left.y, bottom_right.y):
			# Set all tiles on layer 1 to walls
			tilemap.set_cell(1, Vector2i(x, y), 1, Vector2i(0, 3), 0)
	print("Wall tiles placed.")
	
	# Carve out rooms and corridors
	var corridors = [] # One corridor per connection
	for room in $Rooms.get_children():
		var size = (room.size / tile_size).floor()
		var position = tilemap.local_to_map(room.position)
		var room_top_left = (room.position / tile_size).floor() - size
		for x in range(2, size.x * 2 - 1):
			for y in range(2, size.y * 2 - 1):
				# Set floor tiles for layer 0
				tilemap.set_cell(
				0, 
				Vector2i(room_top_left.x + x, 
				room_top_left.y + y), 
				1, 
				Vector2i(1, 1), 0)
				# Clear wall tiles for layer 1
				tilemap.set_cell(
				1, 
				Vector2i(room_top_left.x + x, 
				room_top_left.y + y), 
				-1)
		var current_room_id = path.get_closest_point(room.position)
		for target_room_id in path.get_point_connections(current_room_id):
			# Consider both directions without duplicating corridors
			var connection_pair = {current_room_id: null, target_room_id: null}
			if not connection_pair in corridors:
				var starting_point = tilemap.local_to_map(Vector2(
					path.get_point_position(current_room_id).x, 
					path.get_point_position(current_room_id).y))
				var ending_point = tilemap.local_to_map(Vector2(
					path.get_point_position(target_room_id).x, 
					path.get_point_position(target_room_id).y))
				carve_path(tilemap, starting_point, ending_point)
				corridors.append(connection_pair)
	print("Rooms and corridors carved.")

func carve_path(tilemap : TileMap, start, end):
	# Carve a path between two points
	var difference_x = sign(end.x - start.x)
	var difference_y = sign(end.y - start.y)
	
	if difference_x == 0:
		difference_x = pow(-1.0, randi() % 2)
	if difference_y == 0:
		difference_y = pow(-1.0, randi() % 2)
	
	# Choose either x/y or x/y
	var x_over_y = start
	var y_over_x = end
	
	if randi() % 2 > 0:
		x_over_y = end
		y_over_x = start

	for x in range(start.x, end.x, difference_x):
		# Make corridors 2-tiles wide
		tilemap.set_cell(0, Vector2i(x, x_over_y.y), 1, Vector2i(1, 1), 0);
		tilemap.set_cell(1, Vector2i(x, x_over_y.y), -1)
		tilemap.set_cell(0, Vector2i(x, x_over_y.y + difference_y), 1, Vector2i(1, 1), 0);
		tilemap.set_cell(1, Vector2i(x, x_over_y.y + difference_y), -1)
	for y in range(start.y, end.y, difference_y):
		tilemap.set_cell(0, Vector2i(y_over_x.x, y), 1, Vector2i(1, 1), 0);
		tilemap.set_cell(1, Vector2i(y_over_x.x, y), -1)
		tilemap.set_cell(0, Vector2i(y_over_x.x + difference_x, y), 1, Vector2i(1, 1), 0);
		tilemap.set_cell(1, Vector2i(y_over_x.x + difference_x, y), -1)

func generate_columns(tilemap: TileMap, num_columns: int):
	var rooms = $Rooms.get_children()
	var valid_rooms = []
	
	# Filter out rooms that are too small to have columns
	for room in rooms:
		var size = (room.size / tile_size).floor()
		if size.x >= min_size + 2 and size.y >= min_size + 2 and not room.is_arena:
			valid_rooms.append(room)
	
	# Randomly select rooms to have columns
	for i in range(min(num_columns, valid_rooms.size())):
		var room = valid_rooms[randi() % valid_rooms.size()]
		var size = (room.size / tile_size).floor()
		var center = tilemap.local_to_map(room.position)
		
		# Determine column size (example: based on room size)
		var column_size = Vector2(max(2, size.x / 4), max(2, size.y / 4))
		var column_top_left = center - column_size / 2
		
		# Place the column tiles
		for x in range(column_top_left.x, column_top_left.x + column_size.x):
			for y in range(column_top_left.y, column_top_left.y + column_size.y):
				tilemap.set_cell(1, Vector2i(x, y), 1, Vector2i(0, 3), 0) # Wall tiles on layer 1
				tilemap.set_cell(0, Vector2i(x, y), -1) # Clear floor tiles on layer 0
	
	print("Columns generated in rooms.")

func add_to_graph(graph, room):
	var id = graph.get_available_point_id()
	graph_id_to_room[id] = room
	graph.add_point(id, room.position)
	room.graph_id = id
	return id

func build_graph():
	var rooms = []
	for room in $Rooms.get_children():
		rooms.append(room)

	graph_id_to_room = Dictionary()
	
	path = AStar2D.new()
	add_to_graph(path, start_room)
	rooms.erase(start_room)
	
	var max_degree = 1
	
	# Repeat until no more nodes remain
	while rooms:
		var min_distance = INF # Minimum distance so far
		var min_position_room = null
		var current_position = null
		
		# Loop through all points in the path
		for p1 in path.get_point_ids():
			var p1_room = graph_id_to_room[p1]
			if (p1_room.is_start or p1_room.is_end) and p1_room.corridor_count >= max_degree:
				continue
					
			var p1_position = path.get_point_position(p1)
			#loop though the remaining nodes
			for p2_room in rooms:
				if (p2_room.is_start or p2_room.is_end) and p2_room.corridor_count >= max_degree:
					continue

				var dist = p1_position.distance_to(p2_room.position)
				if dist < min_distance:
					min_distance = dist
					min_position_room = p2_room
					current_position = p1_position
		var source_id = path.get_closest_point(current_position)
		var destination_id = add_to_graph(path, min_position_room)
		path.connect_points(source_id, destination_id)
		graph_id_to_room[source_id].corridor_count += 1
		min_position_room.corridor_count += 1
		rooms.erase(min_position_room)

func create_corridors_from_graph():
	for point in path.get_point_ids():
		for connection in path.get_point_connections(point):
			var pp = path.get_point_position(point)
			var cp = path.get_point_position(connection)
			# instantiate a path
			var current_corridor = corridor.instantiate()
			current_corridor.make_corridor(pp, cp)
			$Corridors.add_child(current_corridor)
			
			var current_room = graph_id_to_room[connection]

func find_start_and_end_rooms():
	var min_axis = INF
	var max_axis = -INF
	for room in $Rooms.get_children():
		if room.is_queued_for_deletion():
			continue
		if y_bias > x_bias:
			if room.position.y < min_axis:
				end_room = room
				min_axis = room.position.y
			if room.position.y > max_axis:
				start_room = room
				max_axis = room.position.y
		else:
			if room.position.x < min_axis:
				end_room = room
				min_axis = room.position.x
			if room.position.x > max_axis:
				start_room = room
				max_axis = room.position.x
	start_room.is_start = true
	end_room.is_end = true

func create_start_and_end_rooms(current_start_room, current_end_room):
	var new_start_room = room.instantiate()
	var new_start_room_width = min_size + randi() % 3
	var new_start_room_height = min_size + randi() % 3

	var new_end_room = room.instantiate()
	var new_end_room_width = min_size + randi() % 3
	var new_end_room_height = min_size + randi() % 3

	# New start room should be below the current start room, and new end room should be above the current end room
	var start_coordinates = Vector2(current_start_room.position.x, current_start_room.position.y + (current_start_room.size.y * 2))
	var end_coordinates = Vector2(current_end_room.position.x, current_end_room.position.y - (current_end_room.size.y * 2))

	new_start_room.make_room(start_coordinates, Vector2(new_start_room_width, new_start_room_height) * tile_size)
	current_start_room.is_start = false
	new_start_room.is_start = true
	start_room = new_start_room
	$Rooms.add_child(start_room)
	new_start_room.freeze

	new_end_room.make_room(end_coordinates, Vector2(new_end_room_width, new_end_room_height) * tile_size)
	current_end_room.is_end = false
	new_end_room.is_end = true
	end_room = new_end_room
	$Rooms.add_child(end_room)
	new_end_room.freeze

func find_main_path():
	var path_from_start_to_end = path.get_id_path(start_room.graph_id, end_room.graph_id)
	
	var i = 0
	for id in path_from_start_to_end:
		graph_id_to_room[id].main_path_index = i
		i += 1

func create_cycles():
	if path_cycles <= 0:
		return
	
	var leaf_nodes = []
	var graph_connections = {}
	
	# Find leaf nodes and create a map of connections
	var full_map_size = Rect2()
	for room in $Rooms.get_children():
		var connections = path.get_point_connections(room.graph_id)
		graph_connections[room.graph_id] = connections
		if connections.size() == 1 and not room.is_start and not room.is_end:
			leaf_nodes.append(room)
		
		var rectangle = Rect2(
			room.position - room.size, 
			room.get_node("CollisionShape2D").shape.extents * 2)
		full_map_size = full_map_size.merge(rectangle)
	
	var section_height = full_map_size.size.y / path_cycles
	
	# Create cycles based on the number of cycles requested
	var cycles_created = 0
	for cycle_index in range(path_cycles):
		var section_start = cycle_index * section_height
		var section_end = section_start + section_height
		var section_leaf_nodes = leaf_nodes.filter(func(room):
			return room.position.y >= section_start and room.position.y < section_end
		)
		
		if section_leaf_nodes.is_empty():
			continue
		
		var chosen_room = section_leaf_nodes[randi() % section_leaf_nodes.size()]
		var closest_room = find_closest_room(chosen_room, section_leaf_nodes)
		
		if closest_room and not path.are_points_connected(chosen_room.graph_id, closest_room.graph_id):
			path.connect_points(chosen_room.graph_id, closest_room.graph_id, true)
			create_corridor(chosen_room.position, closest_room.position)
			cycles_created += 1
			print("Cycle created between: ", chosen_room, " and ", closest_room)

		if cycles_created >= path_cycles:
			break

func find_closest_room(chosen_room, section_leaf_nodes):
	var min_distance = INF
	var closest_room = null
	var radius = 100  # Define a suitable radius for proximity check

	# First pass: Find closest room with one connection
	for room in section_leaf_nodes:
		if room == chosen_room:
			continue
		var distance = chosen_room.position.distance_to(room.position)
		if distance < min_distance and distance <= radius:
			min_distance = distance
			closest_room = room

	# If no close leaf node is found, find the closest room with two connections
	if closest_room == null:
		for room in $Rooms.get_children():
			var connections = path.get_point_connections(room.graph_id)
			if room == chosen_room or connections.size() != 2:
				continue
			var distance = chosen_room.position.distance_to(room.position)
			if distance < min_distance and not path.are_points_connected(chosen_room.graph_id, room.graph_id):
				min_distance = distance
				closest_room = room

	return closest_room

func generate_diverse_rooms():
	# Splitting up room variety to be more controlled and varied
	var elongated_rooms_count = num_rooms / 5
	var arena_rooms_count = num_rooms / 10
	var cramped_rooms_count = num_rooms / 5
	var random_rooms_count = num_rooms - (elongated_rooms_count + arena_rooms_count + cramped_rooms_count)
	
	# Create a set of rooms that are elongated
	for i in range(elongated_rooms_count):
		var room_position = Vector2(randf_range(-x_bias, x_bias), randf_range(-y_bias, y_bias))
		var current_room = room.instantiate()
		var room_size = Vector2.ZERO
		# Favor rooms elongated along the y-axis
		if randf() < 0.5:
			room_size = Vector2(randf_range(min_size, min_size - 2), randf_range(max_size, max_size + 2))
		else:
			room_size = Vector2(randf_range(max_size, max_size - 2), randf_range(min_size, min_size + 2))
		current_room.make_room(room_position, room_size * tile_size)
		$Rooms.add_child(current_room)
	
	# Create a set of arena rooms that are large and proportionate
	for i in range(arena_rooms_count):
		var room_position = Vector2(randf_range(-x_bias, x_bias), randf_range(-y_bias, y_bias))
		var current_room = room.instantiate()
		var room_size = Vector2(max_size + 2 + randi() % 3, max_size + 2 + randi() % 3)
		current_room.make_room(room_position, room_size * tile_size)
		current_room.is_arena = true
		$Rooms.add_child(current_room)
	
	# Create a set of cramped rooms that are small and proportionate
	for i in range(cramped_rooms_count):
		var room_position = Vector2(randf_range(-x_bias, x_bias), randf_range(-y_bias, y_bias))
		var current_room = room.instantiate()
		var room_size = Vector2(min_size + randi() % 3, min_size + randi() % 3)
		current_room.make_room(room_position, room_size * tile_size)
		$Rooms.add_child(current_room)

	# Make remaining rooms truly random
	for i in range(random_rooms_count):
		var room_position = Vector2(randf_range(-x_bias, x_bias), randf_range(-y_bias, y_bias))
		var current_room = room.instantiate()
		var room_size = Vector2(min_size + randi() % (max_size - min_size), min_size + randi() % (max_size - min_size))
		current_room.make_room(room_position, room_size * tile_size)
		$Rooms.add_child(current_room)

func create_corridor(start_position, end_position):
	var new_corridor = corridor.instantiate()
	new_corridor.make_corridor(start_position, end_position)
	$Corridors.add_child(new_corridor)

func explore_distances(start_room):
	var visited = {}
	var queue = []

	queue.append([0, start_room.graph_id])

	while queue.size() > 0:
		var current = queue.pop_front()
		var current_distance = current[0]
		var current_id = current[1]

		if current_id in visited:
			continue

		visited[current_id] = current_distance

		for connection in path.get_point_connections(current_id):
			queue.append([current_distance + 1, connection])
	
	return visited

func assign_distance_index():
	var distances = explore_distances(start_room)
	for room in $Rooms.get_children():
		room.distance_index = distances[room.graph_id]
