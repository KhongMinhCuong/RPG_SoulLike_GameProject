## AOEArrow - Mũi tên nổ cho Archer
## Gây 80% damage, tạo explosion khi hit enemy hoặc trap khi hit wall
class_name AOEArrow
extends "res://Player/Scripts/Projectiles/player_projectile.gd"

# === AOE CONFIG ===
@export var explosion_radius: float = 80.0
@export var explosion_damage_percent: float = 0.8  # 80% of arrow damage
@export var trap_duration: float = 3.0
@export var trap_damage_percent: float = 0.5  # 50% damage
@export var trap_tick_rate: float = 0.5  # Damage mỗi 0.5s

# Scenes
var explosion_effect_scene: PackedScene = null
var trap_scene: PackedScene = null

func _ready() -> void:
	super._ready()
	
	# Try to load effect scenes
	if ResourceLoader.exists("res://Player/Scenes/Projectiles/Effects/explosion_effect.tscn"):
		explosion_effect_scene = load("res://Player/Scenes/Projectiles/Effects/explosion_effect.tscn")
	if ResourceLoader.exists("res://Player/Scenes/Projectiles/Effects/arrow_trap.tscn"):
		trap_scene = load("res://Player/Scenes/Projectiles/Effects/arrow_trap.tscn")

func _handle_hit(target: Node) -> void:
	# Skip nếu đã hit target này rồi
	if target in hit_enemies:
		return
	
	# Skip player
	if target == owner_player or target.is_in_group("player"):
		return
	
	# Check nếu hit enemy hay wall
	if target.is_in_group("enemy") or target.has_method("take_damage"):
		# Hit enemy -> Explosion
		_create_explosion(target)
	elif target.is_in_group("wall") or target is TileMap or target is StaticBody2D:
		# Hit wall -> Create trap
		_create_trap()
	else:
		# Unknown target, treat as wall
		_create_trap()
	
	_destroy()

func _create_explosion(hit_target: Node) -> void:
	"""Tạo explosion gây damage AoE"""
	hit_enemies.append(hit_target)
	
	# Deal damage to hit target
	var direct_damage = _calculate_damage()
	if hit_target.has_method("take_damage"):
		hit_target.take_damage(direct_damage)
	elif hit_target.has_method("apply_damage"):
		hit_target.apply_damage(direct_damage)
	
	hit_enemy.emit(hit_target, direct_damage)
	
	# Find nearby enemies for AoE damage
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = explosion_radius
	query.shape = circle
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 2  # Enemy layer
	
	var results = space_state.intersect_shape(query)
	var aoe_damage = damage * explosion_damage_percent
	
	for result in results:
		var collider = result.collider
		if collider != hit_target and collider not in hit_enemies:
			if collider.has_method("take_damage"):
				collider.take_damage(aoe_damage)
				hit_enemies.append(collider)
				print("[AOEArrow] Explosion hit %s for %.1f damage" % [collider.name, aoe_damage])
	
	# Spawn explosion effect
	_spawn_explosion_effect()

func _create_trap() -> void:
	"""Tạo trap tại vị trí hit wall"""
	if trap_scene:
		var trap = trap_scene.instantiate()
		trap.global_position = global_position
		trap.setup(damage * trap_damage_percent, trap_duration, trap_tick_rate, owner_player)
		get_tree().current_scene.add_child(trap)
		print("[AOEArrow] Trap created at %s" % global_position)
	else:
		# Fallback: spawn simple trap
		_spawn_simple_trap()

func _spawn_explosion_effect() -> void:
	"""Spawn visual explosion effect"""
	if explosion_effect_scene:
		var effect = explosion_effect_scene.instantiate()
		effect.global_position = global_position
		get_tree().current_scene.add_child(effect)
	else:
		# Simple flash effect
		pass

func _spawn_simple_trap() -> void:
	"""Tạo trap đơn giản nếu không có scene"""
	var trap = ArrowTrap.new()
	trap.global_position = global_position
	trap.setup(damage * trap_damage_percent, trap_duration, trap_tick_rate, owner_player)
	get_tree().current_scene.add_child(trap)
