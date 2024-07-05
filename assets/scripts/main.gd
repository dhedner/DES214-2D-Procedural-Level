extends Node2D

var room = preload("res://assets/scenes/room.tscn")
var corridor = preload("res://assets/scenes/corridor.tscn")
var player = preload("res://assets/scenes/player.tscn")
@onready var map = $TileMap

@export var tile_size = 32
@export var num_rooms = 20
@export var min_size = 5
@export var max_size = 9
@export var x_bias = 100
@export var y_bias = 300
@export var path_cycles = 1

var path : AStar2D # Graph that contains all the rooms and their corridors
var graph_id_to_room
var shortest_path_astar = AStar2D.new() # AStar for shortest path
var player_spawn = null
var debug_mode = true
var start_room = null
var end_room = null

func _ready():
	randomize()
	await make_rooms()

func _draw():
	if !debug_mode:
		return

func _process(delta):
	queue_redraw()

func _input(event):
	if event.is_action_pressed("ui_select"):
		clear_map()
		if !debug_mode:
			debug_mode = true
			$Camera2D.enabled = true
		for r in $Rooms.get_children():
			r.queue_free()
		await get_tree().process_frame
		path = null
		make_rooms()
	
	if event.is_action_pressed("ui_focus_next"):
		generate_tiles()
	
	if event.is_action_pressed("ui_cancel"):
		player_spawn = player.instantiate()
		add_child(player_spawn)
		player_spawn.position = start_room.position
		debug_mode = false
		$Camera2D.enabled = false

func clear_map():
	map.clear()
	
	if player_spawn:
		player_spawn.queue_free()
	
	for r in $Rooms.get_children():
		r.queue_free()
	
	for c in $Corridors.get_children():
		c.queue_free()
	
	path = null

func make_rooms():
	for i in range(num_rooms):
		var room_position = Vector2(randf_range(-x_bias, x_bias), randf_range(-y_bias, y_bias))
		var current_room = room.instantiate()
		var room_width = min_size + randi() % (max_size - min_size)
		var room_height = min_size + randi() % (max_size - min_size)
		current_room.make_room(room_position, Vector2(room_width, room_height) * tile_size)
		$Rooms.add_child(current_room)
	# Wait for rooms to settle via physics engine
	await get_tree().create_timer(1.1).timeout
	
	var full_map = Rect2()
	for room in $Rooms.get_children():
		room.freeze = true;
		var rectangle = Rect2(
			room.position - room.size, 
			room.get_node("CollisionShape2D").shape.extents * 2)
		full_map = full_map.merge(rectangle)
	
	find_start_and_end_rooms()
	
	# Generate a minimum spanning tree
	build_graph()
	create_corridors_from_graph()
	find_main_path()
	create_cycles()
	
	check_room_distribution(full_map)

func check_room_distribution(map_size):
	if ((map_size.size.x / 2) > map_size.size.y) or ((map_size.size.y / 2) > map_size.size.x):
		print("Undesirable map size: ", map_size.size)
		clear_map()
		for r in $Rooms.get_children():
			r.queue_free()
		await get_tree().process_frame
		path = null
		make_rooms()

func generate_tiles():
	map.clear()

	# Fill entire map with wall tiles
	var full_rect = Rect2()
	for room in $Rooms.get_children():
		var rectangle = Rect2(
			room.position - room.size, 
			room.get_node("CollisionShape2D").shape.extents * 2)
		full_rect = full_rect.merge(rectangle)
		
	var top_left = map.local_to_map(full_rect.position)
	var bottom_right = map.local_to_map(full_rect.end)
	for x in range (top_left.x, bottom_right.x):
		for y in range (top_left.y, bottom_right.y):
			map.set_cell(0, Vector2i(x, y), 1, Vector2i(1, 1), 0)
		
	# Carve out rooms
	var corridors = [] # One corridor per connection
	
	for room in $Rooms.get_children():
		var size = (room.size / tile_size).floor()
		var position = map.local_to_map(room.position)
		var room_top_left = (room.position / tile_size).floor() - size
		for x in range(2, size.x * 2 - 1):
			for y in range(2, size.y * 2 - 1):
				map.set_cell(
				0, 
				Vector2i(room_top_left.x + x, 
				room_top_left.y + y), 
				1, 
				Vector2i(0, 3), 0)
		var current_path = path.get_closest_point(room.position)
		for connection in path.get_point_connections(current_path):
			if not connection in corridors:
				var starting_point = map.local_to_map(Vector2(
					path.get_point_position(current_path).x, 
					path.get_point_position(current_path).y))
				var ending_point = map.local_to_map(Vector2(
					path.get_point_position(connection).x, 
					path.get_point_position(connection).y))
				carve_path(starting_point, ending_point)
			corridors.append(current_path)

func carve_path(start, end):
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
		map.set_cell(0, Vector2i(x, x_over_y.y), 1, Vector2i(0, 3), 0);
		map.set_cell(0, Vector2i(x, x_over_y.y + difference_y), 1, Vector2i(0, 3), 0);
	for y in range(start.y, end.y, difference_y):
		map.set_cell(0, Vector2i(y_over_x.x, y), 1, Vector2i(0, 3), 0);
		map.set_cell(0, Vector2i(y_over_x.x + difference_x, y), 1, Vector2i(0, 3), 0);

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
			
			if current_room.is_end:
				current_corridor.locked = true

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
	
	# Find dead ends (leaves) and create map of connections
	for room in $Rooms.get_children():
		var connections = path.get_point_connections(room.graph_id)
		graph_connections[room.graph_id] = connections
		# Find all dead ends (not including start/end rooms)
		if connections.size() == 1 and not room.is_start and not room.is_end:
			leaf_nodes.append(room)
	
	var leaf_pairs = find_leaf_pairs(leaf_nodes, graph_connections)
	if leaf_pairs.is_empty():
		return
	
	# Sort pairs by physical distance
	#leaf_pairs.sort_custom(LeafPairComparator)
	#
	#var cycles_created = 0
	#for pair in leaf_pairs:
		#if cycles_created >= path_cycles:
			#break
		#var node_a = pair[0]
		#var node_b = pair[1]
		#if not path.are_points_connected(node_a.graph_id, node_b.graph_id):
			#path.connect_points(node_a.graph_id, node_b.graph_id, false)
			#create_corridor(node_a.position, node_b.position)
			#cycles_created += 1
			#print("Cycle created between: ", node_a, " and ", node_b)
	
	# Create cycles based on defined constraint
	var cycles_created = 0
	while cycles_created < path_cycles:
		#var leaf_pairs = find_leaf_pairs(leaf_nodes, graph_connections)
		var closest_pair = null
		var min_physical_distance = INF
		if leaf_pairs.is_empty():
			return
		else:
			#for leaf in leaf_nodes:
				#if leaf.is_on_main_path or leaf.is_start or leaf.is_end:
					#continue
				#for main_path_id in path.get_point_ids():
					#var main_room = graph_id_to_room[main_path_id]
					#if main_room.main_path_index > 0:
						#path.connect_points(leaf.graph_id, main_room.graph_id, false)
						#create_corridor(leaf.position, main_room.position)
						#cycles_created += 1
						#print("Fallback cycle created between leaf: ", leaf, " and main path node: ", main_room)
						#return
			for pair in leaf_pairs:
				if cycles_created >= path_cycles:
					break
				var node_a = pair[0]
				var node_b = pair[1]
				var physical_distance = node_a.position.distance_to(node_b.position)
				
				if physical_distance < min_physical_distance:
					min_physical_distance = physical_distance
					closest_pair = pair
				
			var node_a = closest_pair[0]
			var node_b = closest_pair[1]
			if not path.are_points_connected(node_a.graph_id, node_b.graph_id):
				path.connect_points(node_a.graph_id, node_b.graph_id, false)
				create_corridor(node_a.position, node_b.position)
				cycles_created += 1
				print("Cycle created between: ", node_a, " and ", node_b)
			leaf_pairs.erase(closest_pair)
			

func find_leaf_pairs(leaf_nodes, graph_connections):
	var pairs = []
	var max_distance = 2
	
	for i in range(leaf_nodes.size()):
		for j in range(i + 1, leaf_nodes.size()):
			var node_a = leaf_nodes[i]
			var node_b = leaf_nodes[j]
			var distance = get_branch_distance(node_a, node_b)
			if distance <= max_distance:
				#var physical_distance = node_a.position.distance_to(node_b.position)
				pairs.append([node_a, node_b])
	return pairs

func get_branch_distance(node_a, node_b):
	var path_a = get_path_to_root(node_a)
	var path_b = get_path_to_root(node_b)
	
	# Find common ancestor
	var common_ancestor = -1
	var min_distance = INF
	for i in range(path_a.size()):
		for j in range(path_b.size()):
			if path_a[i] == path_b[j]:
				var distance = i + j
				if distance < min_distance:
					min_distance = distance
					common_ancestor = path_a[i]
	
	#if common_ancestor == -1:
		#return INF
	
	var distance_a = path_a.size() - path_a.find(common_ancestor) - 1
	var distance_b = path_b.size() - path_b.find(common_ancestor) - 1
	print("distance: ", max(distance_a, distance_b))
	return max(distance_a, distance_b)

func get_path_to_root(node):
	var current_node = node
	var current_path = []
	
	while current_node != null:
		current_path.append(current_node.graph_id)
		var connections = path.get_point_connections(current_node.graph_id)
		if connections.size() > 0:
			current_node = graph_id_to_room[connections[0]]
		else:
			current_node = null
	
	return path

func create_corridor(start_position, end_position):
	var new_corridor = corridor.instantiate()
	new_corridor.make_corridor(start_position, end_position)
	$Corridors.add_child(new_corridor)
