extends RigidBody2D

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
	
func make_room(_position, _size):
	position = _position
	size = _size
	var new_shape = RectangleShape2D.new()
	new_shape.custom_solver_bias = 0.75 # Make the rooms settle quicker
	new_shape.extents = size
	$CollisionShape2D.shape = new_shape

# Change to use various layers of the same tile map (0 for floor)
func generate_room_tiles(tilemap: TileMap):
	var room_size_in_tiles_float = (size / tilemap.tile_set.tile_size.x).floor()
	room_size_in_tiles = Vector2i(room_size_in_tiles_float.x, room_size_in_tiles_float.y)
	room_position_in_tiles = tilemap.local_to_map(position)
	room_top_left = room_position_in_tiles - room_size_in_tiles / 2
	for x in range(room_size_in_tiles.x):
		for y in range(room_size_in_tiles.y):
			var tile_position = Vector2i(x, y) + room_top_left

			# Set floor tiles for layer 0
			tilemap.set_cell(0, tile_position, 1, Vector2i(1, 1), 0)

			# Clear wall tiles for layer 1
			tilemap.set_cell(1, tile_position, -1)

			# print("roomid=", graph_id, " floor=", tile_position)

func add_room_objects(level_manager, tilemap):
	pass

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
