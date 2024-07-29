extends RigidBody2D

var font = preload("res://assets/fonts/LiberationSans.ttf")

var size
var is_start = false
var is_end = false
var is_leading_to_end = false
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
var room_rect : Rect2i
var room_safe_rect : Rect2i
var room_walls_rect : Rect2i
var used_floor_tile_positions = {}
var floor_tile_positions = []
var corridor_tile_positions = []
var door_tile_positions = []
var corridors = []
var objects_for_completion = []
var pickups_for_completion = []
var room_type = RoomType.UNKNOWN
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

@export var draw_debug = false

func _draw():
	if not draw_debug or room_type == RoomType.UNKNOWN:
		return
	
	# Draw the room rectangle
	draw_rect(Rect2(
		get_local_from_tileset(room_rect.position),
		room_rect.size * tilemap.tile_set.tile_size),
		room_colors[room_type])

	# Draw the room safe rectangle
	draw_rect(Rect2(
		get_local_from_tileset(room_safe_rect.position),
		room_safe_rect.size * tilemap.tile_set.tile_size),
		Color(1, 1, 1, 0.2))
	
	# Draw corner rect
	draw_rect(debug_corner_rect, Color(1, 0, 0, 0.1))

	# Draw the door tiles
	for tile_position in door_tile_positions:
		var tile_local_position = get_local_from_tileset(tile_position)
		draw_rect(Rect2(tile_local_position, tilemap.tile_set.tile_size), Color(1, 1, 1, 0.5))

func _process(delta):
	queue_redraw()

func make_room(_position, _size):
	position = _position
	size = _size
	var new_shape = RectangleShape2D.new()
	new_shape.custom_solver_bias = 0.75 # Make the rooms settle quicker
	new_shape.extents = size
	$CollisionShape2D.shape = new_shape

func spawn_with_policy(level_manager, objects_to_spawn):
	for object_descriptor in objects_to_spawn:
		var types_to_spawn = []
		var tile_positions = []
		if object_descriptor["type"] is Callable:
			types_to_spawn = object_descriptor["type"].call(level_manager, self)
			tile_positions = get_tiles_for_placement(
				object_descriptor["placement"], 
				len(types_to_spawn),
				true)
		else:
			tile_positions = get_tiles_for_placement(
				object_descriptor["placement"], 
				object_descriptor["count"].call(level_manager, self),
				true)
			types_to_spawn.append(object_descriptor["type"])

		for i in range(len(tile_positions)):
			# Cycle through the types if there are more than 1
			var object_instance = types_to_spawn[i % len(types_to_spawn)].instantiate()
			add_child(object_instance)
			object_instance.position = get_local_from_tileset(tile_positions[i])

			if object_descriptor["destroy_to_complete"]:
				objects_for_completion.append(object_instance)

			print("Spawning ", object_descriptor["type"], " at ", object_instance.position)

func add_terrain_with_policy(level_manager, terrain_to_spawn):
	for terrain_descriptor in terrain_to_spawn:
		var tile_positions = get_tiles_for_placement(
			terrain_descriptor["placement"], 
			terrain_descriptor["count"].call(level_manager, self),
			terrain_descriptor["is_blocking_tiles"])

		tilemap.set_cells_terrain_connect(
			terrain_descriptor["layer"], 
			tile_positions, 
			0,
			terrain_descriptor["terrain"])

		print("Spawning terrain=", terrain_descriptor["terrain"], " layer=", terrain_descriptor["layer"], " count=", tile_positions.size())

func add_cleared_pickup(level_manager, objects_to_spawn, on_room_complete_callback):
	if len(objects_to_spawn) == 0:
		return

	# Spawn the objects
	for object_descriptor in objects_to_spawn:
		# Get eligible tiles for placement
		var tile_positions = get_tiles_for_placement(
			object_descriptor["placement"], 
			object_descriptor["count"].call(level_manager, self),
			true)
		
		pickups_for_completion.append({
			"tile_positions": tile_positions,
			"object_descriptor": object_descriptor,
			"on_room_complete_callback": on_room_complete_callback
		})

func wait_for_pickups():
	# Wait for all objects in objects_for_completion to be completed
	for object_instance in objects_for_completion:
		if object_instance != null:
			await object_instance.completed

	for pickup_descriptor in pickups_for_completion:
		var tile_positions = pickup_descriptor["tile_positions"]
		var object_descriptor = pickup_descriptor["object_descriptor"]
		var on_room_complete_callback = pickup_descriptor["on_room_complete_callback"]

		# Spawn the object
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
	tilemap.set_cells_terrain_connect(2, tile_positions, 0, 2)

func pass_1(level_manager):
	# Compute the room type
	if is_start:
		room_type = RoomType.START
	elif is_end:
		room_type = RoomType.END
	elif main_path_index == 1:
		room_type = RoomType.TUTORIAL
	elif is_arena:
		room_type = RoomType.ARENA
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
	room_rect = Rect2i(room_top_left, room_size_in_tiles)
	room_safe_rect = Rect2i(room_top_left + Vector2i(1, 1), room_size_in_tiles - Vector2i(2, 2))
	room_walls_rect = Rect2i(room_top_left - Vector2i(1, 1), room_size_in_tiles + Vector2i(2, 2))

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
	# Add corridor tiles to corridor_tile_positions if they are part of the floor
	var created_door_tiles = []
	for tile_position in corridor_tiles:
		if floor_tile_positions.find(tile_position) == -1:
			continue
		
		corridor_tile_positions.append(tile_position)

		# Get the "door" tiles that are in the room rect but not in the safe room rect
		if room_rect.has_point(tile_position) and !room_safe_rect.has_point(tile_position):
			created_door_tiles.append(tile_position)

	door_tile_positions.append_array(created_door_tiles)

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

func get_tiles_for_placement(placement_type, placement_count, blocks_tiles):
	# Copy & filter out the used positions
	var tile_positions = floor_tile_positions.filter(
		func (tile_position): return !used_floor_tile_positions.has(tile_position) and room_safe_rect.has_point(tile_position))

	match placement_type:
		PlacementType.RANDOM:
			# Shuffle the positions
			tile_positions.shuffle()

		PlacementType.FLOOR:
			pass

		PlacementType.NORTH_WALL:
			tile_positions = []

			# Get all the tiles in the tilemap inside room_walls_rect that have the north wall property
			for x in range(room_walls_rect.size.x):
				for y in range(room_walls_rect.size.y):
					var tile_position = room_walls_rect.position + Vector2i(x, y)
					# Filter out used
					if used_floor_tile_positions.has(tile_position):
						continue
					
					var tile_data = tilemap.get_cell_tile_data(1, tile_position)
					if tile_data:
						if tile_data.get_custom_data("is_north_wall"):
							tile_positions.append(tile_position)

			# Stagger every few tiles
			tile_positions = tile_positions.filter(
				func (tile_position): 
					var offset = tile_position - room_top_left
					return offset.x % 2 == 0)

		PlacementType.DOORS:
			tile_positions = door_tile_positions.filter(func (tile_position): return !used_floor_tile_positions.has(tile_position))

		PlacementType.ALL_FLOOR_GRID_3X3_SPACING:
			tile_positions = tile_positions.filter(
				func (tile_position): 
					var offset = tile_position - room_top_left
					return offset.x % 3 == 0 and offset.y % 3 == 0)

		PlacementType.ALL_FLOOR_GRID_4X4_SPACING:
			tile_positions = tile_positions.filter(
				func (tile_position): 
					var offset = tile_position - room_top_left
					return offset.x % 4 == 0 and offset.y % 4 == 0)

		PlacementType.GRID_2X2_CENTERED:
			tile_positions = tile_positions.filter(
				func (tile_position): 
					var offset = tile_position - room_top_left
					return offset.x % 2 == 0 and offset.y % 2 == 0)

			# Find the positions in floor_tile_positions that are closest to the center
			var center = room_position_in_tiles
			tile_positions.sort_custom(
				func (a, b): return (a - center).length_squared() < (b - center).length_squared())

		PlacementType.GRID_4X4_CENTERED:
			tile_positions = tile_positions.filter(
				func (tile_position): 
					var offset = tile_position - room_top_left
					return offset.x % 4 == 0 and offset.y % 4 == 0)

			# Find the positions in floor_tile_positions that are closest to the center
			var center = room_position_in_tiles
			tile_positions.sort_custom(
				func (a, b): return (a - center).length_squared() < (b - center).length_squared())

		PlacementType.CENTER:
			# Find the positions in floor_tile_positions that are closest to the center
			var center = room_position_in_tiles
			tile_positions.sort_custom(
				func (a, b): return (a - center).length_squared() < (b - center).length_squared())

	tile_positions = tile_positions.slice(0, placement_count)

	# Mark them as used
	if blocks_tiles:
		for tile_position in tile_positions:
			used_floor_tile_positions[tile_position] = true

	return tile_positions

func _to_string():
	return "room id=" + str(graph_id) + " type=" + str(room_type) + " distance_index=" + str(distance_index) + " distance_score=" + str(distance_score)
