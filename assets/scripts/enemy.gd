extends Node2D
class_name Enemy

@onready var actor = $CharacterBody2D
@onready var healthbar = $HealthBar

@export var pathfinding: Pathfinding
@export var item_scenes: Array[PackedScene] = []
@export var item_drop_rate: float

func _ready():
	print("Enemy ready")
	# get the pathfinding node from the root of the scene
	pathfinding = get_node("/root/Pathfinding")
	healthbar.set_enemy(self)
	actor.connect("enemy_died", on_enemy_death)

func on_enemy_death():
	queue_free()
	drop_item()

func drop_item():
	if item_scenes.size() == 0:
		return
	
	if randf() > item_drop_rate:
		var random_item = item_scenes[randi() % item_scenes.size()]
		var item_instance = random_item.instantiate()
		item_instance.position = position
		get_parent().add_child(item_instance)
