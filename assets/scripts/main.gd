extends Node2D

var room = preload("res://assets/scenes/room.tscn")
var corridor = preload("res://assets/scenes/corridor.tscn")
var player = preload("res://assets/scenes/player.tscn")
@onready var map = $TileMap

@export var tile_size = 32
@export var num_rooms = 15
@export var min_size = 5
@export var max_size = 9
@export var x_bias = 100
@export var y_bias = 300
#@export var cull_percentage = 0.2

var path # Graph that contains all the rooms and their corridors
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
		#player_spawn = player.instantiate()
		#add_child(player_spawn)
		#player_spawn.position = start_room.position
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
	# Remove a portion of the rooms
	var usable_room_positions = []
	
	for room in $Rooms.get_children():
		room.freeze = true;
	
	find_start_and_end_rooms()
	
	# Generate a minimum spanning tree
	build_graph()
	
	for point in path.get_point_ids():
		for connection in path.get_point_connections(point):
			var pp = path.get_point_position(point)
			var cp = path.get_point_position(connection)
			# instantiate a path
			var current_corridor = corridor.instantiate()
			current_corridor.make_corridor(pp, cp)
			$Corridors.add_child(current_corridor)
			
	find_main_path()

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
	
	# Prim's
	path = AStar2D.new()
	add_to_graph(path, rooms.pop_front())
	
	# Repeat until no more nodes remain
	while rooms:
		var min_distance = INF # Minimum distance so far
		var min_position_room = null
		var current_position = null
		
		# Loop through all points in the path
		for p1 in path.get_point_ids():
			var p3
			p3 = path.get_point_position(p1)
			#loop though the remaining nodes
			for p2_room in rooms:
				var dist = p3.distance_to(p2_room.position)
				if dist < min_distance:
					min_distance = dist
					min_position_room = p2_room
					current_position = p3
		var neighbor = add_to_graph(path, min_position_room)
		path.connect_points(path.get_closest_point(current_position), neighbor)
		rooms.erase(min_position_room)

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
		graph_id_to_room[id].index = i
		i += 1
	
	#var graph = {}
	#var start_room = null
	#var end_room = null
	#
	#for room in $Rooms.get_children():
		#if room.is_start:
			#start_room = room
		#if room.is_end:
			#end_room = room
		#shortest_path_astar.add_point(room.get_instance_id(), room.position)
#
	#for room in $Rooms.get_children():
		#for other_room in $Rooms.get_children():
			#if room != other_room and room.position.distance_to(other_room.position) <= (tile_size * max_size):
				#shortest_path_astar.connect_points(room.get_instance_id(), other_room.get_instance_id(), false)
#
	#var path_points = shortest_path_astar.get_id_path(start_room.get_instance_id(), end_room.get_instance_id())
	#assign_indices_to_path(path_points)
#
#func assign_indices_to_path(path_points):
	#for i in range(path_points.size()):
		#var room_id = path_points[i]
		#var room = instance_from_id(room_id)
		#room.index = i + 1
		#room.is_on_main_path = true
	#
	#for room in $Rooms.get_children():
		#if room.get_instance_id() not in path_points:
			#room.index = -1
			#room.is_on_main_path = false
