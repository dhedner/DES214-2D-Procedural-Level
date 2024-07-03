extends Node2D

var start_position
var end_position

func make_corridor(_start, _end):
	start_position = _start
	end_position = _end

func _draw():
	draw_line(start_position, end_position, Color(1, 1, 0), 15, true)
