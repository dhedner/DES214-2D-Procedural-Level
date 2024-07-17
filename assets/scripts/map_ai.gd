extends Node2D

var enemy_turret = preload("res://assets/scenes/enemy_turret.tscn")
var enemy_shooter = preload("res://assets/scenes/enemy_shooter.tscn")
var enemy_fighter = preload("res://assets/scenes/enemy_fighter.tscn")

var pathfinding: Pathfinding

@onready var enemy_container = $EnemyContainer

func initialize(pathfinding: Pathfinding):
	self.pathfinding = pathfinding

func spawn_enemy_shooter(spawn_location: Vector2):
	var shooter_instance = enemy_shooter.instantiate()
	shooter_instance.global_position = spawn_location
	enemy_container.add_child(shooter_instance)
	shooter_instance.ai.pathfinding = pathfinding

func spawn_enemy_turret(spawn_location: Vector2):
	var turret_instance = enemy_turret.instantiate()
	turret_instance.global_position = spawn_location
	enemy_container.add_child(turret_instance)

func spawn_enemy_fighter(spawn_location: Vector2):
	var fighter_instance = enemy_fighter.instantiate()
	fighter_instance.global_position = spawn_location
	enemy_container.add_child(fighter_instance)
	fighter_instance.ai.pathfinding = pathfinding

func spawn_gameplay_components():
	pass
