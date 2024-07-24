extends CharacterBody2D
class_name Enemy

@onready var ai = $AI
@onready var health_stat = $Health
@onready var weapon = $Weapon
@onready var bullet_manager = $BulletManager
@onready var healthbar = $HealthBar

@export var item_scenes: Array[PackedScene] = []
@export var optimal_range : int = 3 : set = _set_range, get = _get_range
@export var move_speed : float = 100 : set = _set_speed, get = _get_speed
@export var pathfinding: Pathfinding

signal enemy_health_changed(new_health)

func _ready():
	ai.initialize(self, weapon, pathfinding)
	#healthbar.set_enemy(self)

func handle_hit(damage):
	health_stat.health -= damage
	print("enemy hurt")
	emit_signal("enemy_health_changed", health_stat.health)
	if health_stat.health <= 0:
		queue_free()
		drop_item()
	
func _set_range(value):
	optimal_range = value

func _get_range():
	return optimal_range

func _set_speed(value):
	move_speed = value

func _get_speed():
	return move_speed

func drop_item():
	var random_item = item_scenes[randi() % item_scenes.size()]
	var item_instance = random_item.instantiate()
	item_instance.position = position
	get_parent().add_child(item_instance)
