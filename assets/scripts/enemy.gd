extends Node2D
class_name Enemy

@onready var health_stat = $Health
@onready var weapon = $Weapon
@onready var bullet_manager = $BulletManager
@onready var healthbar = $HealthBar

@export var pathfinding: Pathfinding
@export var item_scenes: Array[PackedScene] = []

signal enemy_health_changed(new_health)

func _ready():
	pathfinding = get_node("/root/Pathfinding")
	healthbar.set_enemy(self)

func handle_hit(damage):
	health_stat.health -= damage
	emit_signal("enemy_health_changed", health_stat.health)
	if health_stat.health <= 0:
		queue_free()
		drop_item()

func drop_item():
	var random_item = item_scenes[randi() % item_scenes.size()]
	var item_instance = random_item.instantiate()
	item_instance.position = position
	get_parent().add_child(item_instance)
