extends Node2D

signal state_changed(new_state)
signal enemy_fired_bullet(bullet, position, direction)

enum State {
	PATROL,
	ENGAGE
}

@onready var actor = $".."
@onready var player_detection_zone = $PlayerDetectionZone
@onready var patrol_timer = $PatrolTimer
@onready var bullet_manager = $"../../BulletManager"
@onready var weapon = $"../Weapon"
@onready var light = $"../PointLight2D"

@export var optimal_range: int
@export var movement_speed: int
@export var weapon_cooldown: float
@export var patrol_range: int

var current_state: int = -1 : set = set_state
var player = null

# Patrol state
var origin = Vector2.ZERO
var patrol_location: Vector2 = Vector2.ZERO
var patrol_location_reached = false

# Engage state
var detection_shape: CircleShape2D
var original_shape_radius: float = 0.0

var pathfinding: Pathfinding
var target : Vector2 = Vector2.ZERO
var patrol_light_color : Color
var engage_light_color : Color = Color.RED

func _ready():
	pathfinding = get_tree().get_current_scene().get_node("./Pathfinding")
	self.origin = actor.global_position

	detection_shape = player_detection_zone.shape_owner_get_shape(0, 0) as CircleShape2D
	original_shape_radius = detection_shape.radius
	patrol_light_color = light.color

	enemy_fired_bullet.connect(Callable(bullet_manager, "handle_bullet_spawned"))
	weapon.connect("weapon_fired", shoot)
	weapon.set_cool_down(weapon_cooldown)

	set_state(State.PATROL)
	
func _draw():
	pass
	# draw_circle(position, detection_shape.radius, Color(1, 0, 0, 0.5))
	
func _process(delta):
	queue_redraw()	

func _physics_process(delta):
	# interpolate the light's texture scale based on the detection shape's radius
	light.texture_scale = lerpf(light.texture_scale, detection_shape.radius / 30, 0.1)

	match current_state:
		State.PATROL:
			pass
		State.ENGAGE:
			light.color = engage_light_color.lerp(patrol_light_color, 0.1)
			if player != null:
				var path = pathfinding.get_new_path(actor.global_position, player.global_position)
				var min_optimal = optimal_range * 0.8
				var max_optimal = optimal_range * 1.2
				if path.size() > 1:
					var dist = actor.global_position.distance_to(player.global_position)
					# The enemy is too close to the player, move away
					if dist > max_optimal:
						target = path[1]
						actor.velocity = actor.global_position.direction_to(target) * movement_speed
						actor.rotation = lerp_angle(rotation, actor.velocity.angle(), 1.0)
						actor.move_and_slide()
					# The enemy is too far from the player, move closer
					elif dist < min_optimal:
						target = path[1]
						actor.velocity = actor.global_position.direction_to(target).rotated(deg_to_rad(180)) * movement_speed
						actor.rotation = lerp_angle(actor.rotation, actor.global_position.direction_to(player.global_position).angle(), 1.0)
						actor.move_and_slide()
					# Optimal range is met, stop moving
					else:
						actor.velocity = Vector2.ZERO
						actor.rotation = lerp_angle(actor.rotation, actor.global_position.direction_to(player.global_position).angle(), 1.0)
				weapon.shoot()
			else:
				set_state(State.PATROL)

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
	var random_x = randf_range(-patrol_range, patrol_range)
	var random_y = randf_range(-patrol_range, patrol_range)
	patrol_location = Vector2(random_x, random_y) + origin
	patrol_location_reached = false
