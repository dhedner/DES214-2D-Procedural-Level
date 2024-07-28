extends RigidBody2D

enum RoomType {
	START,
	END,
	ARENA,
	ON_MAIN_PATH,
	OFF_MAIN_PATH,
	TUTORIAL,
}

var font = preload("res://assets/fonts/LiberationSans.ttf")

var size
var is_start = false
var is_end = false
var main_path_index = -1
var distance_index = -1
var graph_id
var corridor_count = 0
var is_on_main_path = false
var is_arena = false
var room_size_in_tiles : Vector2i
var room_position_in_tiles : Vector2i
var room_top_left : Vector2i
var floor_tile_positions = []
var room_type : RoomType

var debug_corner_rect = Rect2()

func _draw():
	draw_rect(debug_corner_rect, Color(1, 0, 0, 0.3))

func _process(delta):
	queue_redraw()

func make_room(_position, _size):
	position = _position
	size = _size
	var new_shape = RectangleShape2D.new()
	new_shape.custom_solver_bias = 0.75 # Make the rooms settle quicker
	new_shape.extents = size
	$CollisionShape2D.shape = new_shape

func pass_1(level_manager, tilemap: TileMap):
	# Set room rectangle parameters
	var room_size_in_tiles_float = (size / tilemap.tile_set.tile_size.x).floor()
	room_size_in_tiles = Vector2i(room_size_in_tiles_float.x, room_size_in_tiles_float.y)
	room_position_in_tiles = tilemap.local_to_map(position)
	room_top_left = room_position_in_tiles - room_size_in_tiles / 2

	floor_tile_positions = []
	for x in range(room_size_in_tiles.x):
		for y in range(room_size_in_tiles.y):
			floor_tile_positions.append(Vector2i(x, y) + room_top_left)

	# # Check if this room should be L-shaped
	# if randf() < level_manager.l_shaped_probability:
	# 	var corner_rect = Rect2i()
	# 	var corridor_clearance = Vector2i(level_manager.corridor_size / 2, level_manager.corridor_size / 2)

	# 	# Pick a corner to chop off and make space for the corridor
	# 	var corner_choice = randi() % 4
	# 	if corner_choice == 0:
	# 		# Top-left
	# 		corner_rect = Rect2i(room_top_left - corridor_clearance, room_size_in_tiles)
	# 	elif corner_choice == 1:
	# 		# Top-right
	# 		corner_rect = Rect2i(room_top_left + Vector2i(room_size_in_tiles.x, -corridor_clearance.y), room_size_in_tiles)
	# 	elif corner_choice == 2:
	# 		# Bottom-right
	# 		corner_rect = Rect2i(room_top_left + room_size_in_tiles - corridor_clearance, room_size_in_tiles)
	# 	elif corner_choice == 3:
	# 		# Bottom-left
	# 		corner_rect = Rect2i(room_top_left + Vector2i(-corridor_clearance.x, room_size_in_tiles.y), room_size_in_tiles)
		
	# 	debug_corner_rect = Rect2(tilemap.map_to_local(corner_rect.position), tilemap.map_to_local(corner_rect.position + corner_rect.size))

	# 	# # Filter out the corner tiles
	# 	# for tile_position in floor_tile_positions:
	# 	# 	if corner_rect.has_point(tile_position):
	# 	# 		floor_tile_positions.erase(tile_position)

	# Set the floor tiles in layer 0
	tilemap.set_cells_terrain_connect(0, floor_tile_positions, 0, 1)
	tilemap.set_cells_terrain_connect(1, floor_tile_positions, 0, -1)

func pass_2(level_manager, tilemap):
	# Compute the room type
	if is_start:
		room_type = RoomType.START
		return

	if is_end:
		room_type = RoomType.END
		return

	if is_arena:
		room_type = RoomType.ARENA
		return

	if is_on_main_path:
		room_type = RoomType.ON_MAIN_PATH
		return

	if not is_on_main_path:
		room_type = RoomType.OFF_MAIN_PATH
		return

func add_columns(level_manager, tilemap):
	# Too small to have columns
	if size.x < level_manager.min_size + 2 or size.y < level_manager.min_size + 2 or is_arena:
		return

	if randf() >= level_manager.column_probability:
		return
	
	# Put columns 

	# # Place the column tiles
	# for x in range(column_top_left.x, column_top_left.x + column_size.x):
	# 	for y in range(column_top_left.y, column_top_left.y + column_size.y):
	# 		tilemap.set_cell(1, Vector2i(x, y), 1, Vector2i(0, 3), 0) # Wall tiles on layer 1
	# 		tilemap.set_cell(0, Vector2i(x, y), -1) # Clear floor tiles on layer 0
	
	print("Columns generated in rooms.")
