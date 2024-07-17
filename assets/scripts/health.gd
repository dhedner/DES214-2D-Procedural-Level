extends Node2D

@export var max_health = 100 : set = _set_max_health, get = _get_max_health
@export var health = max_health : set = _set_health, get = _get_health


func _set_health(new_health):
	health = clamp(new_health, 0, max_health)

func _get_health():
	return health

func _set_max_health(new_max_health):
	max_health = new_max_health
	health = min(health, max_health)

func _get_max_health():
	return max_health
