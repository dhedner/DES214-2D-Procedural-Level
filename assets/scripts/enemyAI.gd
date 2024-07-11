extends Node2D

signal state_changed(new_state)
#signal enemy_fired_bullet(bullet, position, direction)

enum State {
	PATROL,
	ENGAGE
}

enum Variety {
	TURRET,
	RANGER,
	FIGHTER,
	BOSS
}

@onready var player_detection_zone = $PlayerDetectionZone
@onready var patrol_timer = $PatrolTimer
#@onready var bullet_manager = $"../BulletManager"

var current_state: int = -1 : set = set_state
var player = null
var weapon = null
var actor: CharacterBody2D = null

# Patrol state
var origin = Vector2.ZERO
var patrol_point = Vector2.ZERO
var point_reached = false

func _ready():
	actor = self.actor
	set_state(State.PATROL)
	#weapon.connect("weapon_fired", shoot)
	#enemy_fired_bullet.connect(Callable(bullet_manager, "handle_bullet_spawned"))

func _physics_process(delta):
	match current_state:
		State.PATROL:
			if not point_reached:
				actor.move_and_slide()
				actor.rotation = lerp_angle(rotation, global_position.direction_to(patrol_point).angle(), 1.0)
				if actor.global_position.distance_to(patrol_point) < 5:
					point_reached = true
					actor.velocity = Vector2.ZERO
					patrol_timer.start()
		State.ENGAGE:
			if player != null:
				actor.rotation = actor.global_position.direction_to(player.global_position).angle()
				weapon.shoot()

# Pseudo constructor
func initialize(actor, weapon):
	self.actor = actor
	self.weapon = weapon

func set_state(new_state: int):
	if new_state == current_state:
		return
	
	if new_state == State.PATROL:
		origin = global_position
		patrol_timer.start()
		point_reached = true
	
	current_state = new_state
	emit_signal("state_changed", current_state)

func set_weapon(weapon):
	self.weapon = weapon

#func shoot(bullet_instance, location, direction):
	#emit_signal("enemy_fired_bullet", bullet_instance, location, direction)

func _on_player_detection_zone_body_entered(body):
	var name = body.name
	if body.name == "Player":
		set_state(State.ENGAGE)
		player = body

func _on_player_detection_zone_body_exited(body):
	if body.name == "Player":
		set_state(State.PATROL)
		player = null

func _on_patrol_timer_timeout():
	var patrol_range = 50
	var random_x = randf_range(-patrol_range, patrol_range)
	var random_y = randf_range(-patrol_range, patrol_range)
	patrol_point = Vector2(random_x, random_y) + origin
	point_reached = false
	actor.velocity = actor.global_position.direction_to(patrol_point) * 100
