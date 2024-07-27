extends ProgressBar

@onready var enemy = $".."
@onready var enemy_actor = $"../CharacterBody2D"
@onready var health = $"../Health"

func _ready():
	set_new_health_value(health.max_health)

func _process(delta):
	global_position = enemy.global_position + Vector2(-50, -50)

func set_enemy(enemy: Enemy):
	self.enemy = enemy
	set_new_health_value(enemy_actor.health_stat.max_health)
	enemy_actor.connect("enemy_health_changed", set_new_health_value)

func set_new_health_value(new_health: int):
	var bar_style = self.get("theme_override_styles/fill")
	var original_color = Color("dc2922")
	var highlighter_color = Color("ff7e7e")
	var health_tween = create_tween()

	health_tween.tween_property(self, "value", new_health, 0.3).set_ease(Tween.EASE_IN).set_delay(Tween.TRANS_LINEAR)
	if enemy_actor.connect("enemy_health_changed", Callable(self, "set_new_health_value")):
		health_tween.tween_property(bar_style, "bg_color", highlighter_color, 0.2).set_ease(Tween.EASE_IN).set_delay(Tween.TRANS_LINEAR)
		health_tween.tween_property(bar_style, "bg_color", original_color, 0.2).set_ease(Tween.EASE_OUT).set_delay(Tween.TRANS_LINEAR)
