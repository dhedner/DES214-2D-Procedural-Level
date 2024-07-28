extends Node2D

var source_room
var destination_room
var locked = false

@onready var tilemap : TileMap = get_tree().get_root().get_node("Main/TileMap")

func make_corridor(_source_room, _destination_room):
	source_room = _source_room
	destination_room = _destination_room
	source_room.corridors.append(self)
	destination_room.corridors.append(self)

func generate_corridor_tiles(path):
	var starting_point = tilemap.local_to_map(Vector2(
		path.get_point_position(source_room.graph_id).x, 
		path.get_point_position(source_room.graph_id).y))
	var ending_point = tilemap.local_to_map(Vector2(
		path.get_point_position(destination_room.graph_id).x, 
		path.get_point_position(destination_room.graph_id).y))

	# Carve a path between two points
	var difference_x = sign(ending_point.x - starting_point.x)
	var difference_y = sign(ending_point.y - starting_point.y)
	
	# They are on the same x/y axis, so pick a random direction
	if difference_x == 0:
		difference_x = pow(-1.0, randi() % 2)
	if difference_y == 0:
		difference_y = pow(-1.0, randi() % 2)

	# Choose either x/y or y/x
	var x_over_y = starting_point
	var y_over_x = ending_point
	
	if randi() % 2 > 0:
		x_over_y = ending_point
		y_over_x = starting_point

	var corridor_tiles = []
	for x in range(starting_point.x, ending_point.x, difference_x):
		# Make corridors 2-tiles wide
		corridor_tiles.append(Vector2i(x, x_over_y.y))
		corridor_tiles.append(Vector2i(x, x_over_y.y + difference_y))

	for y in range(starting_point.y, ending_point.y, difference_y):
		# Make corridors 2-tiles wide
		corridor_tiles.append(Vector2i(y_over_x.x, y))
		corridor_tiles.append(Vector2i(y_over_x.x + difference_x, y))

	source_room.add_corridor_tiles(corridor_tiles)
	destination_room.add_corridor_tiles(corridor_tiles)
