extends Node2D
class_name Pathfinding

var astar = AStar2D.new()
var tilemap: TileMap
var half_cell_size: Vector2
var used_rect: Rect2

func create_navigation_map(_tilemap: TileMap):
	self.tilemap = _tilemap
	
	half_cell_size = tilemap.tile_set.tile_size / 2
	used_rect = tilemap.get_used_rect()
	
	# Get the floor tiles (tiles on layer 0)
	var tiles = tilemap.get_used_cells(0)
	
	add_traversable_tiles(tiles)
	connect_traversable_tiles(tiles)

# Add vertices to a grid
func add_traversable_tiles(tiles: Array):
	for tile in tiles:
		var id = get_id_for_point(tile)
		astar.add_point(id, tile)

# Go through vertices and connect them as necessary
func connect_traversable_tiles(tiles: Array):
	for tile in tiles:
		var id = get_id_for_point(tile)

		for x in range(3):
			for y in range(3):
				var target = tile + Vector2i(x - 1, y - 1)
				var target_id = get_id_for_point(target)

				if tile == target or not astar.has_point(target_id):
					continue
				
				astar.connect_points(id, target_id, true)

func get_id_for_point(point: Vector2):
	var x = point.x - used_rect.position.x
	var y = point.y - used_rect.position.y

	return x + y * used_rect.size.x

# Start and end are both in world coordinates
func get_new_path(start: Vector2, end: Vector2):
	var start_id = get_id_for_point(tilemap.local_to_map(start + half_cell_size))
	var end_id = get_id_for_point(tilemap.local_to_map(end + half_cell_size))

	if not astar.has_point(start_id) or not astar.has_point(end_id):
		return []

	var path_map = astar.get_point_path(start_id, end_id)
	var path_world = []

	for point in path_map:
		var point_world = tilemap.map_to_local(point) -	half_cell_size
		path_world.append(point_world)
	
	if path_world.size() > 0:
		path_world.pop_front()
		
	path_world.push_back(end)
	
	return path_world
