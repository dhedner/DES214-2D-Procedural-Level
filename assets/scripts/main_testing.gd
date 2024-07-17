extends Node2D

var player = preload("res://assets/scenes/player.tscn")
var level_exit = preload("res://assets/scenes/level_exit.tscn")
var locked_door = preload("res://assets/scenes/door.tscn")
var key = preload("res://assets/scenes/key.tscn")

@onready var tilemap = $TileMap
@onready var pathfinding = $Pathfinding

var debug_mode = false

func _ready():
	pathfinding.create_navigation_map(tilemap)

func _draw():
	queue_redraw()

