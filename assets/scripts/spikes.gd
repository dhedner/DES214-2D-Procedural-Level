extends Area2D

enum State {
	ACTIVE,
	INACTIVE
}

@export var damage : int = 10

@onready var damage_timer = $Timer

var current_state: int = -1 : set = set_state
var player_in_area: Node = null

func _ready():
	set_state(State.ACTIVE)
	damage_timer.connect("timeout", _on_timer_timeout)

func _process(delta):
	pass

func set_state(new_state: int):
	if new_state == current_state:
		return
	
	current_state = new_state

func _on_body_entered(body):
	if current_state == State.ACTIVE and body.name == "Player" and body.has_method("handle_hit"):
		player_in_area = body
		player_in_area.handle_hit(damage)
		damage_timer.start()

func _on_body_exited(body):
	if body == player_in_area:
		player_in_area = null
		damage_timer.stop()

func _on_timer_timeout():
	if player_in_area and current_state == State.ACTIVE:
		player_in_area.handle_hit(damage)

