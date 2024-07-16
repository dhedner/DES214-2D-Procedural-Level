extends Node2D

var enemy_shooter = preload("res://assets/scenes/enemy_shooter.tscn")

var pathfinding: Pathfinding

@onready var enemy_container = $EnemyContainer

#func _ready():
	#

func initialize(pathfinding: Pathfinding):
	self.pathfinding = pathfinding

func spawn_enemy_shooter(spawn_location: Vector2):
	var shooter_instance = enemy_shooter.instantiate()
	enemy_container.add_child(shooter_instance)
	shooter_instance.global_position = spawn_location
	shooter_instance.ai.pathfinding = pathfinding

func spawn_gameplay_components():
	pass
