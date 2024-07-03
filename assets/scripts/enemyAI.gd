extends Node2D

signal state_changed(new_state)

enum State {
	PATROL,
	ENGAGE
}

@onready var player_detection_zone = $PlayerDetectionZone

var current_state: int = State.PATROL : set = set_state
var player = null
var actor = null

func _ready():
	actor = self.actor

func _process(delta):
	match current_state:
		State.PATROL:
			pass
		State.ENGAGE:
			if player != null:
				actor.roation = actor.global_position.direction_to(player.global_position)

func set_state(new_state: int):
	if new_state == current_state:
		return
	
	current_state = new_state
	emit_signal("state_changed", current_state)

func _on_body_entered(body):
	if body.name == "player":
		set_state(State.ENGAGE)
		player = body
