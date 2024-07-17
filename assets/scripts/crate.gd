extends StaticBody2D

@export var item_scenes: Array[PackedScene] = []
@export var drop_chance: float = 0.4
@export var health: int = 10

func _ready():
	pass

func handle_hit(amount: int):
	if health - amount <= 0:
		drop_item()
		queue_free()

func drop_item():
	if randf() < drop_chance:
		var random_item = item_scenes[randi() % item_scenes.size()]
		var item_instance = random_item.instantiate()
		item_instance.position = position
		get_parent().add_child(item_instance)
