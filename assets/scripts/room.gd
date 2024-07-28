extends RigidBody2D

var font = preload("res://assets/fonts/LiberationSans.ttf")
var heart_container = preload("res://assets/scenes/heart_container.tscn")
var firerate_pickup = preload("res://assets/scenes/firerate_pickup.tscn")
var health_pickup = preload("res://assets/scenes/health_pickup.tscn")
var swift_boots = preload("res://assets/scenes/swift_boots.tscn")

var size
var is_start = false
var is_end = false
var main_path_index = -1
var distance_index = -1
var distance_score = 0.0 # how far this room is from the start [0.0 -> 1.0]
var graph_id
var corridor_count = 0 # does not count cycles
var is_arena = false
var is_elongated = false
var is_cramped = false
var room_size_in_tiles : Vector2i
var room_position_in_tiles : Vector2i
var room_top_left : Vector2i
var used_floor_tile_positions = {}
var floor_tile_positions = []
var corridor_tile_positions = []
var corridors = []
var objects_for_completion = []
var room_type
@onready var tilemap : TileMap = get_tree().get_root().get_node("Main/TileMap")

var corner_rect = Rect2i()
var debug_corner_rect = Rect2()
var room_colors = {
	RoomType.START: Color(0, 1, 0, 0.3), # Green
	RoomType.END: Color(1, 0, 0, 0.3), # Red
	RoomType.ARENA: Color(0, 0, 1, 0.3), # Blue
	RoomType.ON_MAIN_PATH: Color(1, 1, 0, 0.3), # Yellow
	RoomType.OFF_MAIN_PATH: Color(0, 1, 1, 0.3), # Cyan
	RoomType.TREASURE: Color(1, 0.5, 0, 0.3), # Orange
	RoomType.TUTORIAL: Color(1, 0, 1, 0.3), # Magenta
}

func _draw():
	pass
	# Draw the room rectangle
	# draw_rect(Rect2(Vector2(-size.x / 2, -size.y / 2), Vector2(size.x, size.y)), room_colors[room_type])

	# draw_rect(debug_corner_rect, Color(1, 0, 0, 0.3))

func _process(_delta):
	pass
	# queue_redraw()

func make_room(_position, _size):
	position = _position
	size = _size
	var new_shape = RectangleShape2D.new()
	new_shape.custom_solver_bias = 0.75 # Make the rooms settle quicker
	new_shape.extents = size
	$CollisionShape2D.shape = new_shape

func spawn_with_policy(level_manager, objects_to_spawn):
	for object_descriptor in objects_to_spawn:
		var tile_positions = get_tiles_for_placement(
			object_descriptor["placement"], 
			object_descriptor["count"].call(level_manager, self))

		for tile_position in tile_positions:
			var object_instance = object_descriptor["type"].instantiate()
			add_child(object_instance)
			object_instance.position = get_local_from_tileset(tile_position)

			if object_descriptor["destroy_to_complete"]:
				objects_for_completion.append(object_instance)

			print("Spawning ", object_descriptor["type"], " at ", object_instance.position)

func set_cleared_pickup(level_manager, objects_to_spawn, on_room_complete_callback):
	if len(objects_to_spawn) == 0:
		return

	# Wait for all objects in objects_for_completion to be completed
	for object_instance in objects_for_completion:
		await object_instance.completed

	# Spawn the objects
	for object_descriptor in objects_to_spawn:
		# Get eligible tiles for placement
		var tile_positions = get_tiles_for_placement(
			object_descriptor["placement"], 
			object_descriptor["count"].call(level_manager, self))

		for tile_position in tile_positions:
			var object_instance = object_descriptor["type"].instantiate()
			add_child(object_instance)
			object_instance.position = get_local_from_tileset(tile_position)

			print("Spawning ", object_descriptor["type"], " at ", object_instance.position)

			# Call the on_room_complete_callback
			if on_room_complete_callback:
				on_room_complete_callback.call(self)


func add_floor_tiles(tile_positions, is_corridor):
	# Add floor tiles to the floor layer
	tilemap.set_cells_terrain_connect(0, tile_positions, 0, 1)

	# Remove wall layer collisions
	tilemap.set_cells_terrain_connect(1, tile_positions, 0, -1)
	
	# Floor overlay (such as grates)
	if not is_corridor:
		tilemap.set_cells_terrain_connect(2, tile_positions, 0, 2)

func pass_1(level_manager):
	# Compute the room type
	if is_start:
		room_type = RoomType.START
	elif is_end:
		room_type = RoomType.END
	elif is_arena:
		room_type = RoomType.ARENA
	elif main_path_index == 1:
		room_type = RoomType.TUTORIAL
	elif main_path_index > 1:
		room_type = RoomType.ON_MAIN_PATH
	elif corridor_count == 1:
		room_type = RoomType.TREASURE
	else:
		room_type = RoomType.OFF_MAIN_PATH

	# Compute the distance score
	distance_score = distance_index / float(level_manager.max_distance_index)

	# Set room rectangle parameters
	var room_size_in_tiles_float = (size / tilemap.tile_set.tile_size.x).floor()
	room_size_in_tiles = Vector2i(room_size_in_tiles_float.x, room_size_in_tiles_float.y)
	room_position_in_tiles = tilemap.local_to_map(position)
	room_top_left = room_position_in_tiles - room_size_in_tiles / 2

	make_l_shaped(level_manager)
	compute_floor_tiles()

func compute_floor_tiles():
	floor_tile_positions = []
	for x in range(room_size_in_tiles.x):
		for y in range(room_size_in_tiles.y):
			var tile_position = Vector2i(x, y) + room_top_left
			if not corner_rect.has_point(tile_position):
				floor_tile_positions.append(tile_position)

	add_floor_tiles(floor_tile_positions, false)

func add_corridor_tiles(corridor_tiles):
	add_floor_tiles(corridor_tiles, true)

	# Add corridor tiles to corridor_tile_positions if they are part of the floor
	for tile_position in corridor_tiles:
		if floor_tile_positions.find(tile_position) != -1:
			corridor_tile_positions.append(tile_position)

func make_l_shaped(level_manager):
	# Check if this room should be L-shaped
	if (room_type != RoomType.ON_MAIN_PATH and room_type != RoomType.OFF_MAIN_PATH) or is_elongated:
		return
	
	if randf() > level_manager.l_shaped_probability:
		return

	corner_rect = Rect2i()

	# Pick a corner to chop off and make space for the corridor
	var corner_offset = [
		Vector2i(0, 0), # Bottom right
		Vector2i(-1, 0), # Bottom left
		Vector2i(-1, -1), # Top left
		Vector2i(0, -1), # Top right
	]
	var choice = randi() % 4
	var corner_choice = corner_offset[choice]
	var offset = room_size_in_tiles * corner_choice

	corner_rect = Rect2i(room_position_in_tiles + offset, room_size_in_tiles)	
	debug_corner_rect = Rect2(
		get_local_from_tileset(corner_rect.position),
		corner_rect.size * tilemap.tile_set.tile_size)

	print("room_id=", graph_id, " is L-shaped corner=", choice)

func get_local_from_tileset(tile_position):
	return to_local(tilemap.map_to_local(tile_position))

func get_tiles_for_placement(placement_type, placement_count):
	var tile_positions = []

	# match placement_type:
	# 	PlacementType.CENTER:

	# Find the positions in floor_tile_positions that are closest to the center
	var center = room_position_in_tiles
	# Copy the array so we can sort it
	var closest_positions = floor_tile_positions.duplicate()
	closest_positions.sort_custom(
		func (a, b): return (a - center).length_squared() < (b - center).length_squared())
	# Filter out the used positions
	closest_positions = closest_positions.filter(
		func (tile_position): return !used_floor_tile_positions.has(tile_position))
	tile_positions = closest_positions.slice(0, placement_count)
	
	# Mark them as used
	for tile_position in tile_positions:
		used_floor_tile_positions[tile_position] = true

	return tile_positions

func _to_string():
	return "room id=" + str(graph_id) + " type=" + str(room_type) + " distance_index=" + str(distance_index) + " distance_score=" + str(distance_score)
