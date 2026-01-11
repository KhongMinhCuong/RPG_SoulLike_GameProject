## ArrowTrap - Bẫy tạo bởi AOE Arrow khi hit wall
## Tồn tại trong duration, gây damage cho enemies đi qua
class_name ArrowTrap
extends Area2D

# === CONFIG ===
var trap_damage: float = 15.0
var trap_duration: float = 3.0
var tick_rate: float = 0.5
var owner_player: Node = null

# === STATE ===
var remaining_duration: float = 3.0
var tick_timer: float = 0.0
var enemies_in_trap: Array[Node] = []

func setup(p_damage: float, p_duration: float, p_tick_rate: float, p_owner: Node) -> void:
	trap_damage = p_damage
	trap_duration = p_duration
	tick_rate = p_tick_rate
	owner_player = p_owner
	remaining_duration = p_duration

func _ready() -> void:
	# Setup collision
	collision_layer = 0
	collision_mask = 2  # Enemy layer
	
	# Create collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 40.0
	collision.shape = shape
	add_child(collision)
	
	# Create visual
	_create_visual()
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _process(delta: float) -> void:
	remaining_duration -= delta
	
	if remaining_duration <= 0:
		_destroy_trap()
		return
	
	# Tick damage to enemies in trap
	tick_timer += delta
	if tick_timer >= tick_rate:
		tick_timer -= tick_rate
		_deal_trap_damage()

func _deal_trap_damage() -> void:
	"""Gây damage cho tất cả enemies trong trap"""
	for enemy in enemies_in_trap:
		if is_instance_valid(enemy):
			if enemy.has_method("take_damage"):
				enemy.take_damage(trap_damage)
				print("[ArrowTrap] Dealt %.1f damage to %s" % [trap_damage, enemy.name])
			elif enemy.has_method("apply_damage"):
				enemy.apply_damage(trap_damage)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") and body not in enemies_in_trap:
		enemies_in_trap.append(body)

func _on_body_exited(body: Node) -> void:
	if body in enemies_in_trap:
		enemies_in_trap.erase(body)

func _on_area_entered(area: Area2D) -> void:
	var body = area.get_parent()
	if body and body.is_in_group("enemy") and body not in enemies_in_trap:
		enemies_in_trap.append(body)

func _on_area_exited(area: Area2D) -> void:
	var body = area.get_parent()
	if body in enemies_in_trap:
		enemies_in_trap.erase(body)

func _create_visual() -> void:
	"""Tạo visual cho trap"""
	var visual = Sprite2D.new()
	# Create a simple circle texture
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 0.5, 0, 0.5))  # Orange semi-transparent
	var texture = ImageTexture.create_from_image(image)
	visual.texture = texture
	visual.scale = Vector2(1.5, 1.5)
	visual.modulate = Color(1, 0.6, 0.2, 0.6)
	add_child(visual)
	
	# Pulsing animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(visual, "modulate:a", 0.3, 0.5)
	tween.tween_property(visual, "modulate:a", 0.6, 0.5)

func _destroy_trap() -> void:
	"""Hủy trap"""
	enemies_in_trap.clear()
	queue_free()
