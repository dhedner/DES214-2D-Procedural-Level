extends RigidBody2D

var font = preload("res://assets/fonts/LiberationSans.ttf")

var size
var is_start = false
var is_end = false
var index = 1
var graph_id
var is_on_main_path = false

func make_room(_position, _size):
	position = _position
	size = _size
	var new_shape = RectangleShape2D.new()
	new_shape.custom_solver_bias = 0.75 # Make the rooms settle quicker
	new_shape.extents = size
	$CollisionShape2D.shape = new_shape

func _draw():
	#var room_rect = Rect2(position - size, size * 2)
	var room_rect = Rect2(-size, size * 2)	
	if is_start:
		draw_rect(room_rect, Color(0.0, 0.2, 0.8), true)
	elif is_end:
		draw_rect(room_rect, Color(0.8, 0.2, 0), true)
	else:
		draw_rect(room_rect, Color(0.2, 0.8, 0), false)
	
	draw_string(font, room_rect.position + Vector2(125,125), str(index), HORIZONTAL_ALIGNMENT_LEFT, -1, 100)

func _process(delta):
	queue_redraw()
