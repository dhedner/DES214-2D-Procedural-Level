extends CharacterBody2D

@onready var ai = $AI
@onready var health_stat = $Health
@onready var weapon = $Weapon
@onready var bullet_manager = $BulletManager

func _ready():
	ai.initialize(self, weapon)

func handle_hit():
	health_stat.health -= 20
	print("enemy hurt")
	if health_stat.health <= 0:
		queue_free()
