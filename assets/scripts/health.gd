extends Node2D

@export var health = 100 : set = _set_health, get = _get_health

func _set_health(new_health):
	health = clamp(new_health, 0, 100)

func _get_health():
	return health
