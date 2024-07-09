extends CharacterBody2D

@export var move_speed : float = 100
var bullet = preload("res://assets/scenes/bullet.tscn")

@onready var bullet_manager = $"../BulletManager"

signal player_fired_bullet(bullet, position, direction)

func _ready():
	player_fired_bullet.connect(Callable(bullet_manager, "handle_bullet_spawned"))

func _input(event):
	if event.is_action_pressed('scroll_out'):
		$Camera2D.zoom = $Camera2D.zoom - Vector2(0.1, 0.1)
	if event.is_action_pressed('scroll_in'):
		$Camera2D.zoom = $Camera2D.zoom + Vector2(0.1, 0.1)

func _physics_process(delta):
	var input_direction = get_input()
	velocity = input_direction * move_speed
	move_and_slide()
	
	if input_direction != Vector2.ZERO:
		var target_rotation = input_direction.angle()
		rotation = lerp_angle(rotation, target_rotation, 0.1)

func get_input():
	velocity = Vector2()
	if Input.is_action_pressed('move_right'):
		velocity.x += 1
	if Input.is_action_pressed('move_left'):
		velocity.x -= 1
	if Input.is_action_pressed('move_up'):
		velocity.y -= 1
	if Input.is_action_pressed('move_down'):
		velocity.y += 1
	return velocity.normalized()

func _unhandled_input(event):
	if event.is_action_released("shoot"):
		shoot()

func shoot():
	var bullet_instance = bullet.instantiate()
	var target = get_global_mouse_position()
	var direction_to_mouse = global_position.direction_to(target).normalized()
	emit_signal("player_fired_bullet", bullet_instance, global_position, direction_to_mouse)
