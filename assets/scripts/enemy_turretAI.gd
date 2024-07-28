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

@export var weapon_cooldown: float
@export var patrol_range: int

var current_state: int = -1 : set = set_state
var player = null

# Engage state
var detection_shape: CircleShape2D
var original_shape_radius: float = 0.0

var pathfinding: Pathfinding
var target : Vector2 = Vector2.ZERO
var patrol_light_color : Color
var engage_light_color : Color = Color.RED

func _ready():
	actor = self.actor

	detection_shape = player_detection_zone.shape_owner_get_shape(0, 0) as CircleShape2D
	original_shape_radius = detection_shape.radius
	patrol_light_color = light.color

	enemy_fired_bullet.connect(Callable(bullet_manager, "handle_bullet_spawned"))
	weapon.connect("weapon_fired", shoot)
	weapon.set_cool_down(weapon_cooldown)

	set_state(State.PATROL)

func _physics_process(delta):
	# interpolate the light's texture scale based on the detection shape's radius
	light.texture_scale = lerpf(light.texture_scale, detection_shape.radius / 30, 0.1)

	match current_state:
		State.PATROL:
			light.color = patrol_light_color.lerp(engage_light_color, 0.1)
		State.ENGAGE:
			light.color = engage_light_color.lerp(patrol_light_color, 0.1)
			if player != null and weapon != null:
				actor.rotation = actor.global_position.direction_to(player.global_position).angle()
				weapon.shoot()

func set_state(new_state: int):
	if new_state == current_state:
		return
	
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
