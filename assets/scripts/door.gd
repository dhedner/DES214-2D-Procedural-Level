extends Area2D

@export var is_locked = true

#@onready var collision_shape = $StaticBody2D/CollisionShape2D

#func _draw():
	#var parent_position = position
	#if is_locked:
		#draw_rect(Rect2(parent_position, Vector2(64, 64)), Color(1, 0, 0, 0.5))
	#else:
		#draw_rect(Rect2(parent_position, Vector2(64, 64)), Color(0, 1, 0, 0.5))

func _on_body_entered(body):
	if body.name == "Player" and is_locked and body.has_key:
		unlock()

func unlock():
	is_locked = false
	$StaticBody2D/CollisionShape2D.disabled = true
	$Sprite2D.texture = load("res://assets/sprites/UnlockedDoor.png")

func _process(delta):
	queue_redraw()
