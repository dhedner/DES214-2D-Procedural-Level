extends Node2D

var start_position
var end_position
var source_graph_id
var destination_graph_id
var locked = false

func make_corridor(source_id, source_position, destination_id, destination_position):
	start_position = source_position
	source_graph_id = source_id
	end_position = destination_position
	destination_graph_id = destination_id

func generate_corridor_tiles(tilemap, path):
	var starting_point = tilemap.local_to_map(Vector2(
		path.get_point_position(source_graph_id).x, 
		path.get_point_position(source_graph_id).y))
	var ending_point = tilemap.local_to_map(Vector2(
		path.get_point_position(destination_graph_id).x, 
		path.get_point_position(destination_graph_id).y))

	# Carve a path between two points
	var difference_x = sign(ending_point.x - starting_point.x)
	var difference_y = sign(ending_point.y - starting_point.y)
	
	if difference_x == 0:
		difference_x = pow(-1.0, randi() % 2)
	if difference_y == 0:
		difference_y = pow(-1.0, randi() % 2)
	
	# Choose either x/y or x/y
	var x_over_y = starting_point
	var y_over_x = ending_point
	
	if randi() % 2 > 0:
		x_over_y = ending_point
		y_over_x = starting_point

	for x in range(starting_point.x, ending_point.x, difference_x):
		# Make corridors 2-tiles wide
		tilemap.set_cell(0, Vector2i(x, x_over_y.y), 1, Vector2i(1, 1), 0);
		tilemap.set_cell(1, Vector2i(x, x_over_y.y), -1)
		tilemap.set_cell(0, Vector2i(x, x_over_y.y + difference_y), 1, Vector2i(1, 1), 0);
		tilemap.set_cell(1, Vector2i(x, x_over_y.y + difference_y), -1)
	for y in range(starting_point.y, ending_point.y, difference_y):
		tilemap.set_cell(0, Vector2i(y_over_x.x, y), 1, Vector2i(1, 1), 0);
		tilemap.set_cell(1, Vector2i(y_over_x.x, y), -1)
		tilemap.set_cell(0, Vector2i(y_over_x.x + difference_x, y), 1, Vector2i(1, 1), 0);
		tilemap.set_cell(1, Vector2i(y_over_x.x + difference_x, y), -1)
