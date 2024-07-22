extends CanvasLayer

@onready var health_bar = $MarginContainer/Bars/TopRow/HealthBar

var player: Player

func set_player(player: Player):
	self.player = player
	
	set_new_max_health(player.health_stat.health)
	set_new_health_value(player.health_stat.max_health)

	player.connect("player_health_changed", set_new_health_value)
	player.connect("player_max_health_changed", set_new_max_health)

func set_new_health_value(new_health: int):
	var bar_style = health_bar.get("theme_override_styles/fill")
	var original_color = Color("dc2922")
	var highlighter_color = Color("ff7e7e")
	var health_tween = create_tween()

	health_tween.tween_property(health_bar, "value", new_health, 0.3).set_ease(Tween.EASE_IN).set_delay(Tween.TRANS_LINEAR)
	if player.connect("player_health_changed", Callable(self, "set_new_health_value")):
		health_tween.tween_property(bar_style, "bg_color", highlighter_color, 0.2).set_ease(Tween.EASE_IN).set_delay(Tween.TRANS_LINEAR)
		health_tween.tween_property(bar_style, "bg_color", original_color, 0.2).set_ease(Tween.EASE_OUT).set_delay(Tween.TRANS_LINEAR)

func set_new_max_health(new_max_health: int):
	health_bar.max_value = new_max_health
	# increase the health bar size to match the new max health
	health_bar.size.x = new_max_health * 2
