extends CharacterBody2D
class_name Player

@export var move_speed : float = 100
var has_key = false
var double_defense = false
var god_mode = false

@onready var bullet_manager = $"../BulletManager"
@onready var weapon = $Weapon
@onready var health_stat = $Health

signal player_health_changed(new_health)
signal player_max_health_changed(new_max_health)
signal player_fired_bullet(bullet, position, direction)
signal player_picked_up_key(has_key)
signal player_used_key(has_key)

func _ready():
	weapon.connect("weapon_fired", shoot)
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
	
	look_at(get_global_mouse_position())

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
		weapon.shoot()
	if event.is_action_released("god_mode"):
		god_mode = !god_mode
		print("god mode toggled")

func shoot(bullet_instance, location, direction):
	emit_signal("player_fired_bullet", bullet_instance, location, direction)

func handle_hit(damage):
	if god_mode:
		return
	if double_defense:
		health_stat.health -= damage / 2
	else:
		health_stat.health -= damage
	print("player health: ", health_stat.health)
	emit_signal("player_health_changed", health_stat.health)
	
	if health_stat.health <= 0:
		reset_current_scene()

func pick_up_key():
	has_key = true
	emit_signal("player_picked_up_key", has_key)

# One per level
func pick_up_fire_rate():
	weapon.set_cool_down(0.1)

# Common
func pick_up_health():
	health_stat.health += 20
	print("player health: ", health_stat.health)
	emit_signal("player_health_changed", health_stat.health)

# About 3 per level
func pick_up_health_container():
	health_stat.max_health += 50
	health_stat.health = health_stat.max_health
	emit_signal("player_max_health_changed", health_stat.max_health)
	emit_signal("player_health_changed", health_stat.health)

# One per level
func pick_up_swift_boots():
	move_speed += 80

func unlock_door(door):
	if has_key:
		door.unlock()
		has_key = false
		emit_signal("player_used_key", has_key)

func reset_current_scene():
	get_tree().reload_current_scene()
