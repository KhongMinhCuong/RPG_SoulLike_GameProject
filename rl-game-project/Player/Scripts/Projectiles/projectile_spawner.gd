## ProjectileSpawner - Node để spawn projectiles cho ranged characters
## Thêm node này vào player scene cho các nhân vật ranged
## Hỗ trợ spawn từ hitbox center và arrow type switching
class_name ProjectileSpawner
extends Node2D

# === REFERENCES ===
@export var player_path: NodePath = ".."
@export var hitbox_path: NodePath = "../Hitbox"
var player: Node = null
var hitbox: Area2D = null

# === PROJECTILE SETTINGS ===
@export var projectile_scene: PackedScene  # Default scene
@export var spawn_offset: Vector2 = Vector2(20, -10)  # Offset từ player (fallback)
@export var default_damage: float = 25.0
@export var use_hitbox_center: bool = true  # Spawn từ hitbox center

# === CACHED SCENE (từ Arrow Switch ability) ===
var cached_projectile_scene: PackedScene = null

# === ARROW TYPE SUPPORT ===
var arrow_switch_ability: AbilityBase = null

func _ready() -> void:
	player = get_node_or_null(player_path)
	hitbox = get_node_or_null(hitbox_path)
	
	if not player:
		push_error("[ProjectileSpawner] Player not found at path: %s" % player_path)
	
	# Find arrow switch ability
	_find_arrow_switch_ability()

func _find_arrow_switch_ability() -> void:
	"""Tìm ArcherArrowSwitch ability nếu có"""
	if not player or not player.has_node("AbilityManager"):
		return
	
	await get_tree().process_frame  # Wait for AbilityManager to initialize
	
	var ability_mgr = player.get_node("AbilityManager")
	for ability in ability_mgr.abilities.values():
		if ability.ability_name == "Arrow Switch":
			arrow_switch_ability = ability
			print("[ProjectileSpawner] Found Arrow Switch ability")
			break

## Load projectile scene từ path
func load_projectile_scene(path: String) -> void:
	if path != "" and ResourceLoader.exists(path):
		cached_projectile_scene = load(path)
		print("[ProjectileSpawner] Loaded projectile: %s" % path)
	else:
		push_warning("[ProjectileSpawner] Projectile scene not found: %s" % path)

## Get spawn position (từ hitbox center hoặc offset)
func _get_spawn_position(direction: Vector2) -> Vector2:
	if not player:
		return global_position
	
	# Lấy direction sign để flip offset
	var dir_sign = 1.0 if direction.x >= 0 else -1.0
	
	if use_hitbox_center and hitbox:
		# Tìm collision shape đầu tiên để lấy approximate center
		for child in hitbox.get_children():
			if child is CollisionShape2D:
				# Spawn từ center của collision shape (flip theo direction)
				var shape_pos = child.position
				var spawn_x = abs(shape_pos.x) * dir_sign
				return player.global_position + Vector2(spawn_x, shape_pos.y)
		
		# Fallback: spawn từ hitbox position + default offset
		return player.global_position + Vector2(25.0 * dir_sign, -25)
	else:
		# Fallback: spawn từ player + offset
		return player.global_position + Vector2(
			spawn_offset.x * dir_sign,
			spawn_offset.y
		)

## Get current projectile scene (priority: arrow_switch > cached > default)
func _get_current_scene() -> PackedScene:
	# Priority 1: Arrow Switch ability
	if arrow_switch_ability and arrow_switch_ability.has_method("get_current_arrow_scene"):
		var scene = arrow_switch_ability.get_current_arrow_scene()
		if scene:
			return scene
	
	# Priority 2: Cached scene
	if cached_projectile_scene:
		return cached_projectile_scene
	
	# Priority 3: Default scene
	return projectile_scene

## Get current damage multiplier from Arrow Switch
func _get_damage_multiplier() -> float:
	if arrow_switch_ability and arrow_switch_ability.has_method("get_current_damage_multiplier"):
		return arrow_switch_ability.get_current_damage_multiplier()
	return 1.0

## Spawn projectile
func spawn_projectile(direction: Vector2 = Vector2.RIGHT, custom_damage: float = -1.0) -> Node:
	var scene_to_use = _get_current_scene()
	
	if not scene_to_use:
		push_error("[ProjectileSpawner] No projectile scene assigned!")
		return null
	
	if not player:
		push_error("[ProjectileSpawner] Player reference missing!")
		return null
	
	# Instantiate projectile
	var projectile = scene_to_use.instantiate()
	
	# Calculate damage
	var base_damage = default_damage
	if player.base_stats:
		base_damage = player.base_stats.base_damage
	
	var damage_mult = _get_damage_multiplier()
	var final_damage = custom_damage if custom_damage > 0 else (base_damage * damage_mult)
	
	# Setup projectile
	if projectile.has_method("setup"):
		projectile.setup(direction, player, final_damage)
	else:
		projectile.direction = direction
		projectile.owner_player = player
		projectile.damage = final_damage
	
	# Position
	var spawn_pos = _get_spawn_position(direction)
	projectile.global_position = spawn_pos
	
	# Add to scene
	player.get_tree().current_scene.add_child(projectile)
	
	print("[ProjectileSpawner] Spawned at hitbox center: %s, damage: %.1f" % [spawn_pos, final_damage])
	return projectile

## Spawn projectile theo hướng player đang nhìn
func spawn_facing_projectile(custom_damage: float = -1.0) -> Node:
	var direction = Vector2.RIGHT
	
	# Get direction from player
	if player and "direction" in player:
		direction = Vector2.RIGHT if player.direction >= 0 else Vector2.LEFT
	elif player and player.has_node("Sprite2D"):
		var sprite = player.get_node("Sprite2D")
		direction = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	
	return spawn_projectile(direction, custom_damage)

## Spawn for combo attack (1_atk, 2_atk, 3_atk, air_atk)
func spawn_combo_arrow() -> Node:
	"""Spawn arrow cho combo attack, sử dụng hitbox center"""
	return spawn_facing_projectile()

## Spawn multiple projectiles (spread shot)
func spawn_spread(count: int = 3, spread_angle: float = 15.0, custom_damage: float = -1.0) -> Array:
	var projectiles: Array = []
	var base_direction = Vector2.RIGHT
	
	# Get base direction
	if player and "direction" in player:
		base_direction = Vector2.RIGHT if player.direction >= 0 else Vector2.LEFT
	
	# Calculate spread
	var start_angle = -spread_angle * (count - 1) / 2.0
	
	for i in range(count):
		var angle = start_angle + spread_angle * i
		var direction = base_direction.rotated(deg_to_rad(angle))
		var proj = spawn_projectile(direction, custom_damage)
		if proj:
			projectiles.append(proj)
	
	return projectiles
