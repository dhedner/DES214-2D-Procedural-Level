extends Area2D

enum State {
	ACTIVE,
	INACTIVE
}

@export var damage : int = 10

var current_state: int = -1 : set = set_state

func _ready():
	set_state(State.ACTIVE)

func _process(delta):
	pass

func set_state(new_state: int):
	if new_state == current_state:
		return
	
	current_state = new_state

func _on_body_entered(body):
	if current_state == State.ACTIVE and body.has_method("handle_hit"):
		body.handle_hit(damage)
