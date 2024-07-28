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
var has_corridor = {
	"top": false,
	"right": false,
	"bottom": false,
	"left": false,
}
var room_size_in_tiles : Vector2i
var room_position_in_tiles : Vector2i
var room_top_left : Vector2i
var floor_tile_positions = []
var corridor_tile_positions = []
var room_type : RoomType

var debug_corner_rect = Rect2()

var tilemap : TileMap

func _ready():
	tilemap = get_tree().get_root().get_node("Main/TileMap")

func _draw():
	# Draw the room rectangle
	draw_rect(Rect2(Vector2(-size.x / 2, -size.y / 2), Vector2(size.x, size.y)), Color(0, 0, 1, 0.2))

	if has_corridor["top"]:
		draw_line(Vector2(), Vector2(0, -size.y / 2), Color(1, 0, 0, 0.5), 2)
	if has_corridor["right"]:
		draw_line(Vector2(), Vector2(size.x / 2, 0), Color(1, 0, 0, 0.5), 2)
	if has_corridor["bottom"]:
		draw_line(Vector2(), Vector2(0, size.y / 2), Color(1, 0, 0, 0.5), 2)
	if has_corridor["left"]:
		draw_line(Vector2(), Vector2(-size.x / 2, 0), Color(1, 0, 0, 0.5), 2)

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

func add_floor_tiles(tile_positions, is_corridor):
	# Add floor tiles to the floor layer
	tilemap.set_cells_terrain_connect(0, tile_positions, 0, 1)

	# Remove wall layer collisions
	tilemap.set_cells_terrain_connect(1, tile_positions, 0, -1)
	
	# Floor overlay (such as grates)
	# if not is_corridor:
	tilemap.set_cells_terrain_connect(2, tile_positions, 0, 2)

func pass_1(level_manager):
	# Set room rectangle parameters
	var room_size_in_tiles_float = (size / tilemap.tile_set.tile_size.x).floor()
	room_size_in_tiles = Vector2i(room_size_in_tiles_float.x, room_size_in_tiles_float.y)
	room_position_in_tiles = tilemap.local_to_map(position)
	room_top_left = room_position_in_tiles - room_size_in_tiles / 2

	floor_tile_positions = []
	for x in range(room_size_in_tiles.x):
		for y in range(room_size_in_tiles.y):
			floor_tile_positions.append(Vector2i(x, y) + room_top_left)

	add_floor_tiles(floor_tile_positions, false)

func pass_2(level_manager):
	# Compute the room type
	if is_start:
		room_type = RoomType.START
	elif is_end:
		room_type = RoomType.END
	elif is_arena:
		room_type = RoomType.ARENA
	elif is_on_main_path:
		room_type = RoomType.ON_MAIN_PATH
	else:
		room_type = RoomType.OFF_MAIN_PATH

	make_l_shaped(level_manager)
	add_columns(level_manager)

func add_corridor_tiles(corridor_tiles):
	add_floor_tiles(corridor_tiles, true)

	# Add corridor tiles to corridor_tile_positions if they are part of the floor
	for tile_position in corridor_tiles:
		if floor_tile_positions.find(tile_position) != -1:
			corridor_tile_positions.append(tile_position)

func make_l_shaped(level_manager):
	# Check if this room should be L-shaped

	if room_type == RoomType.START or room_type == RoomType.END or room_type == RoomType.ARENA:
		return
	
	if randf() > level_manager.l_shaped_probability:
		return

	print("room_id: ", graph_id, " is L-shaped.")

	# var corner_rect = Rect2i()
	# var corridor_clearance = Vector2i(level_manager.corridor_size / 2, level_manager.corridor_size / 2)

	# # Pick a corner to chop off and make space for the corridor
	# var corner_choice = randi() % 4
	# if corner_choice == 0:
	# 	# Top-left
	# 	corner_rect = Rect2i(room_top_left - corridor_clearance, room_size_in_tiles)
	# elif corner_choice == 1:
	# 	# Top-right
	# 	corner_rect = Rect2i(room_top_left + Vector2i(room_size_in_tiles.x, -corridor_clearance.y), room_size_in_tiles)
	# elif corner_choice == 2:
	# 	# Bottom-right
	# 	corner_rect = Rect2i(room_top_left + room_size_in_tiles - corridor_clearance, room_size_in_tiles)
	# elif corner_choice == 3:
	# 	# Bottom-left
	# 	corner_rect = Rect2i(room_top_left + Vector2i(-corridor_clearance.x, room_size_in_tiles.y), room_size_in_tiles)
	
	# debug_corner_rect = Rect2(tilemap.map_to_local(corner_rect.position), tilemap.map_to_local(corner_rect.position + corner_rect.size))

	# # Filter out the corner tiles
	# for tile_position in floor_tile_positions:
	# 	if corner_rect.has_point(tile_position):
	# 		floor_tile_positions.erase(tile_position)

func add_columns(level_manager):	
	# Check if this room should have columns

	if size.x < level_manager.min_size + 2 or size.y < level_manager.min_size + 2 or is_arena:
		return

	if randf() >= level_manager.column_probability:
		return

	print("room_id: ", graph_id, " has columns.")
