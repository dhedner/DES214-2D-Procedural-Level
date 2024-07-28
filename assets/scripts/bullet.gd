extends Area2D

@onready var kill_timer = $KillTimer
@export var speed : int = 3 : set = _set_speed, get = _get_speed
@export var damage : int = 20 : set = _set_damage, get = _get_damage

var travel_direction = Vector2.ZERO

func _ready():
	kill_timer.start()

func _process(delta):
	if travel_direction != Vector2.ZERO:
		var velocity = travel_direction * speed
		
		global_position += velocity

func set_direction(new_direction):
	travel_direction = new_direction
	rotation += new_direction.angle()

func _set_speed(new_speed):
	speed = new_speed

func _get_speed():
	return speed

func _set_damage(new_damage):
	damage = new_damage

func _get_damage():
	return damage

func _on_kill_timer_timeout():
	queue_free()

func _on_body_entered(body):
	if body.has_method("handle_hit"):
		body.handle_hit(damage)
	queue_free()
