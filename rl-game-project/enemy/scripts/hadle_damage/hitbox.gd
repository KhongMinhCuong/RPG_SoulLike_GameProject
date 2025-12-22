extends Area2D
class_name Hitbox

var direction: int
var damage: float = 0.0
var owner_node: CharacterBody2D = null

func _ready() -> void:
	owner_node = get_parent() as CharacterBody2D

	if owner_node and "damage" in owner_node:
			damage = owner_node.damage
	else:
		push_warning("Hitbox không tìm thấy node cha có damage")
	
	collision_layer = 3
	collision_mask = 1

	monitoring = false
	monitorable = false
	for shape in get_children():
		if shape is CollisionShape2D:
			shape.disabled = true

func _physics_process(delta: float) -> void:
	direction = owner_node.direction
	scale.x = direction

func enable():
	# Refresh damage from owner in case stats changed after _ready
	if owner_node and "damage" in owner_node:
		damage = owner_node.damage

	monitoring = true
	monitorable = true
	for shape in get_children():
		if shape is CollisionShape2D:
			shape.disabled = false

func enable_shape(shape_index: int):
	"""Enable only specific CollisionShape2D by index"""
	# Refresh damage from owner whenever enabling specific hitbox shape
	if owner_node and "damage" in owner_node:
		damage = owner_node.damage

	monitoring = true
	monitorable = true
	var shapes = get_children().filter(func(c): return c is CollisionShape2D)
	for i in shapes.size():
		shapes[i].disabled = (i != shape_index)

func disable():
	monitoring = false
	monitorable = false
	for shape in get_children():
		if shape is CollisionShape2D:
			shape.disabled = true
