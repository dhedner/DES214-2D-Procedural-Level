extends Node2D

signal weapon_fired(bullet, location, direction)

var bullet = preload("res://assets/scenes/bullet.tscn")

@export var damage: int
@export var speed: int

@onready var reticol = $Reticol
@onready var cooldown = $Cooldown

func shoot():
	if cooldown.is_stopped() and bullet != null:
		var bullet_instance = bullet.instantiate()
		bullet_instance._set_damage(damage)
		bullet_instance._set_speed(speed)
		#var target = get_global_mouse_position()
		var direction = (reticol.global_position - global_position).normalized()
		emit_signal("weapon_fired", bullet_instance, reticol.global_position, direction)
		cooldown.start()

func set_cool_down(time):
	cooldown.set_wait_time(time)
