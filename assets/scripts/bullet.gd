extends Area2D

@onready var kill_timer = $KillTimer
@export var speed : int = 3
@export var damage : int = 20

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

func _on_kill_timer_timeout():
	queue_free()

func _on_body_entered(body):
	# Add check so that bullets don't hit the body that spawned them
	if body.has_method("handle_hit"):
		body.handle_hit(damage)
	queue_free()
