## PoisonEffect - Hiệu ứng độc đính kèm enemy
## Gây damage theo thời gian, stacking
class_name PoisonEffect
extends Node

# === CONFIG ===
var duration: float = 5.0
var damage_per_stack: float = 0.10  # 10% base damage per stack per second
var max_stacks: int = 5
var base_damage: float = 30.0
var owner_player: Node = null

# === STATE ===
var current_stacks: int = 1
var remaining_duration: float = 5.0
var tick_timer: float = 0.0
var tick_interval: float = 1.0  # Damage mỗi 1 giây

# === SIGNALS ===
signal poison_expired()
signal poison_damage_dealt(damage: float)

func setup(p_duration: float, p_damage_per_stack: float, p_max_stacks: int, p_base_damage: float, p_owner: Node) -> void:
	duration = p_duration
	damage_per_stack = p_damage_per_stack
	max_stacks = p_max_stacks
	base_damage = p_base_damage
	owner_player = p_owner
	
	remaining_duration = duration
	current_stacks = 1
	tick_timer = 0.0

func _ready() -> void:
	# Visual indicator
	_create_poison_visual()

func _process(delta: float) -> void:
	remaining_duration -= delta
	
	if remaining_duration <= 0:
		_expire()
		return
	
	# Tick damage
	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer -= tick_interval
		_deal_poison_damage()

func _deal_poison_damage() -> void:
	"""Gây poison damage cho parent"""
	var parent = get_parent()
	if not parent:
		return
	
	# Tính damage: stacks * damage_per_stack * base_damage
	var poison_damage = current_stacks * damage_per_stack * base_damage
	
	if parent.has_method("take_damage"):
		parent.take_damage(poison_damage)
		print("[Poison] Dealt %.1f damage (%d stacks)" % [poison_damage, current_stacks])
	elif parent.has_method("apply_damage"):
		parent.apply_damage(poison_damage)
	
	poison_damage_dealt.emit(poison_damage)
	
	# Visual tick effect
	_show_poison_tick()

func add_stack(new_duration: float, new_base_damage: float) -> void:
	"""Thêm stack và refresh duration"""
	current_stacks = min(current_stacks + 1, max_stacks)
	remaining_duration = new_duration  # Refresh duration
	base_damage = max(base_damage, new_base_damage)  # Use higher base damage

func _expire() -> void:
	"""Poison hết hiệu lực"""
	poison_expired.emit()
	_remove_visual()
	queue_free()

func _create_poison_visual() -> void:
	"""Tạo visual indicator cho poison"""
	var parent = get_parent()
	if parent and parent.has_node("Sprite2D"):
		var sprite = parent.get_node("Sprite2D")
		# Green tint for poison
		sprite.modulate = Color(0.7, 1.0, 0.7, 1.0)

func _show_poison_tick() -> void:
	"""Flash effect khi poison tick"""
	var parent = get_parent()
	if parent and parent.has_node("Sprite2D"):
		var sprite = parent.get_node("Sprite2D")
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(0.4, 0.9, 0.4), 0.1)
		tween.tween_property(sprite, "modulate", Color(0.7, 1.0, 0.7), 0.1)

func _remove_visual() -> void:
	"""Remove poison visual"""
	var parent = get_parent()
	if parent and parent.has_node("Sprite2D"):
		var sprite = parent.get_node("Sprite2D")
		sprite.modulate = Color.WHITE
