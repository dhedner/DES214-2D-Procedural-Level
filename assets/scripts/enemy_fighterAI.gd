extends Node2D

signal state_changed(new_state)
signal enemy_fired_bullet(bullet, position, direction)

enum State {
	PATROL,
	ENGAGE
}

@onready var player_detection_zone = $PlayerDetectionZone
@onready var patrol_timer = $PatrolTimer
@onready var bullet_manager = $"../BulletManager"

# Obtain from base enemy class
@export var optimal_range: int = 2
@export var movement_speed: int = 150

var current_state: int = -1 : set = set_state
var player = null
var weapon = null
var actor: CharacterBody2D = null

# Patrol state
var origin = Vector2.ZERO
var patrol_location: Vector2 = Vector2.ZERO
var patrol_location_reached = false

var pathfinding: Pathfinding
var target : Vector2 = Vector2.ZERO

func _ready():
	actor = self.actor

	enemy_fired_bullet.connect(Callable(bullet_manager, "handle_bullet_spawned"))
	
#func _draw():
	#pass
	#draw_circle(to_local(origin), 11, Color(1, 0, 1))
	#draw_circle(Vector2.ZERO, 11, Color(0, 1, 0))
	#draw_circle(to_local(patrol_location), 8, Color(0, 1, 1))	
	#draw_circle(to_local(target), 5, Color(0, 0, 1))
	#draw_line(Vector2.ZERO, to_local(patrol_location), Color(1, 1, 0), 15, true)

func _process(delta):
	queue_redraw()	

func _physics_process(delta):
	match current_state:
		State.PATROL:
			if not patrol_location_reached :
				var path = pathfinding.get_new_path(actor.global_position, patrol_location)
				if path.size() > 1:
					target = path[1]
					actor.velocity = actor.global_position.direction_to(target) * movement_speed
					#print("moving from ", actor.global_position, " to ", target, " trying to reach ", patrol_location, " velocity ", actor.velocity)
					actor.rotation = lerp_angle(actor.rotation, actor.velocity.angle(), 1.0)
					actor.move_and_slide()
				else:
					patrol_location_reached  = true
					actor.velocity = Vector2.ZERO
					patrol_timer.start()
		State.ENGAGE:
			if player != null:
				var path = pathfinding.get_new_path(actor.global_position, player.global_position)
				var min_optimal = optimal_range * 0.8
				var max_optimal = optimal_range * 1.2
				if path.size() > 1:
					var dist = actor.global_position.distance_to(player.global_position)
					# If optimal range is not met, move towards player
					if dist < min_optimal:
						target = path[1]
						actor.velocity = actor.global_position.direction_to(target) * movement_speed
						actor.rotation = lerp_angle(rotation, actor.velocity.angle(), 1.0)
						actor.move_and_slide()
					# If optimal range is exceeded by a certain amount, move away from player
					elif dist > max_optimal:
						target = path[1]
						actor.velocity = actor.global_position.direction_to(target).rotated(deg_to_rad(180)) * movement_speed
						actor.rotation = lerp_angle(actor.rotation, actor.global_position.direction_to(player.global_position).angle(), 1.0)
						actor.move_and_slide()
					# If optimal range is met, stop moving
					else:
						actor.velocity = Vector2.ZERO
						actor.rotation = lerp_angle(rotation, actor.velocity.angle(), 1.0)
				weapon.shoot()
			else:
				set_state(State.PATROL)

# Pseudo constructor
func initialize(actor, weapon, pathfinding):
	self.actor = actor
	self.weapon = weapon
	self.pathfinding = pathfinding
	self.origin = actor.global_position
	set_state(State.PATROL)
	
	weapon.connect("weapon_fired", shoot)
	weapon.set_cool_down(0.8)


func set_state(new_state: int):
	if new_state == current_state:
		return
	
	if new_state == State.PATROL:
		patrol_timer.start()
		patrol_location_reached = true
	
	current_state = new_state
	emit_signal("state_changed", current_state)

func set_weapon(weapon):
	self.weapon = weapon

func shoot(bullet_instance, location, direction):
	emit_signal("enemy_fired_bullet", bullet_instance, location, direction)

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
	patrol_location = Vector2(random_x, random_y) + origin
	#print("enemy patroling at ", patrol_location, " from origin ", origin)
	patrol_location_reached = false
