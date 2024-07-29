extends CharacterBody2D

@onready var health_stat = $"../Health"

signal enemy_health_changed(new_health)
signal enemy_died()

func handle_hit(damage):
	health_stat.health -= damage
	emit_signal("enemy_health_changed", health_stat.health)
	if health_stat.health <= 0:
		emit_signal("enemy_died")
