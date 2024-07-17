extends Node2D

var start_position
var end_position
var locked = false

func make_corridor(_start, _end):
	start_position = _start
	end_position = _end

#func _draw():
	#draw_line(start_position, end_position, Color(1, 1, 0), 15, true)
	
	#if locked:
		#var lock_position = start_position + (end_position - start_position) / 2.0
		#var lock_size = Vector2(100, 100)
		#draw_rect(Rect2(lock_position - (lock_size / 2.0), Vector2(100, 100)), Color(1.0, 0.5, 0.0), true)
