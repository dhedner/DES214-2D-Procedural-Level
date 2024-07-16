extends CharacterBody2D
class_name Enemy

@onready var ai = $AI
@onready var health_stat = $Health
@onready var weapon = $Weapon
@onready var bullet_manager = $BulletManager

@export var optimal_range : int = 10
@export var move_speed : float = 100

func _ready():
	ai.initialize(self, weapon)

func handle_hit(damage):
	health_stat.health -= damage
	print("enemy hurt")
	if health_stat.health <= 0:
		queue_free()
