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

func _draw():
	pass
	# var room_rect = Rect2(-size, size * 2)	

func _process(delta):
	pass
	# queue_redraw()
	
# Change to use various layers of the same tile map (0 for floor)
func generate_room_tiles(tilemap: TileMap):
	# get the size of the room in tiles as a Vector2i
	var room_size_in_tiles = (size / tilemap.tile_set.tile_size.x).floor()
	room_size_in_tiles = Vector2i(room_size_in_tiles.x, room_size_in_tiles.y)

	var room_position_in_tiles = tilemap.local_to_map(position)
	var room_top_left = room_position_in_tiles - room_size_in_tiles / 2
	for x in range(room_size_in_tiles.x):
		for y in range(room_size_in_tiles.y):
			var tile_position = Vector2i(x, y) + room_top_left

			# Set floor tiles for layer 0
			tilemap.set_cell(0, tile_position, 1, Vector2i(1, 1), 0)

			# Clear wall tiles for layer 1
			tilemap.set_cell(1, tile_position, -1)

			print("FLoor set at: ", tile_position)

func make_room(_position, _size):
	position = _position
	size = _size
	var new_shape = RectangleShape2D.new()
	new_shape.custom_solver_bias = 0.75 # Make the rooms settle quicker
	new_shape.extents = size
	$CollisionShape2D.shape = new_shape
