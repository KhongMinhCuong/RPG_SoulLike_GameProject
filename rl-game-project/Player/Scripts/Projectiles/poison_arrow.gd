## PoisonArrow - Mũi tên độc cho Archer
## Gây 30% damage trực tiếp + Poison DoT
## Poison stacking: mỗi stack +10% base damage/s, max 5 stacks (50%/s)
class_name PoisonArrow
extends "res://Player/Scripts/Projectiles/player_projectile.gd"

# === POISON CONFIG ===
@export var poison_duration: float = 5.0
@export var poison_damage_per_stack: float = 0.10  # 10% base damage per stack per second
@export var max_poison_stacks: int = 5

func _ready() -> void:
	super._ready()

func _handle_hit(target: Node) -> void:
	# Skip nếu đã hit target này rồi
	if target in hit_enemies:
		return
	
	# Skip player
	if target == owner_player or target.is_in_group("player"):
		return
	
	# Check nếu target có thể nhận damage
	if not (target.has_method("take_damage") or target.has_method("apply_damage")):
		return
	
	hit_enemies.append(target)
	
	# Deal direct damage (30%)
	var direct_damage = _calculate_damage()
	if target.has_method("take_damage"):
		target.take_damage(direct_damage)
	elif target.has_method("apply_damage"):
		target.apply_damage(direct_damage)
	
	hit_enemy.emit(target, direct_damage)
	
	# Apply poison effect
	_apply_poison(target)
	
	_destroy()

func _apply_poison(target: Node) -> void:
	"""Apply hoặc refresh poison effect trên target"""
	# Check nếu target đã có PoisonEffect
	var existing_poison: PoisonEffect = null
	for child in target.get_children():
		if child is PoisonEffect:
			existing_poison = child
			break
	
	# Tính base damage từ player
	var base_dmg = owner_player.base_stats.base_damage if owner_player and owner_player.base_stats else damage
	
	if existing_poison:
		# Refresh và add stack
		existing_poison.add_stack(poison_duration, base_dmg)
		print("[PoisonArrow] Added poison stack to %s (now %d stacks)" % [target.name, existing_poison.current_stacks])
	else:
		# Tạo poison effect mới
		var poison = PoisonEffect.new()
		poison.setup(
			poison_duration,
			poison_damage_per_stack,
			max_poison_stacks,
			base_dmg,
			owner_player
		)
		target.add_child(poison)
		print("[PoisonArrow] Applied new poison to %s" % target.name)
