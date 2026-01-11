## ArcherArrowSwitch - Ability chuyển đổi loại tên cho Archer
## 3 loại tên: Normal (150% dmg), AOE (80% + explosion/trap), Poison (30% + DoT)
class_name ArcherPiercingShot
extends "res://Player/Scripts/Abilities/ability_base.gd"

# === ARROW TYPES ===
enum ArrowType { NORMAL, AOE, POISON }
var current_arrow_type: ArrowType = ArrowType.NORMAL

# === ARROW SCENES ===
var arrow_scenes: Dictionary = {}
const ARROW_PATHS: Dictionary = {
	ArrowType.NORMAL: "res://Player/Scenes/Projectiles/normal_arrow.tscn",
	ArrowType.AOE: "res://Player/Scenes/Projectiles/aoe_arrow.tscn",
	ArrowType.POISON: "res://Player/Scenes/Projectiles/poison_arrow.tscn"
}

# === DAMAGE MULTIPLIERS ===
const DAMAGE_MULTIPLIERS: Dictionary = {
	ArrowType.NORMAL: 1.5,   # 150% damage
	ArrowType.AOE: 0.8,      # 80% damage
	ArrowType.POISON: 0.3    # 30% damage
}

# === ARROW NAMES ===
const ARROW_NAMES: Dictionary = {
	ArrowType.NORMAL: "Normal Arrow",
	ArrowType.AOE: "Explosive Arrow",
	ArrowType.POISON: "Poison Arrow"
}

func _on_initialize() -> void:
	ability_name = "Arrow Switch"
	description = "Chuyển đổi loại tên: Normal (150%), AOE (80% + nổ/bẫy), Poison (30% + độc)"
	cooldown = 0.5  # Short cooldown để switch nhanh
	mana_cost = 0.0
	
	# Preload all arrow scenes
	_preload_arrow_scenes()

func _preload_arrow_scenes() -> void:
	for arrow_type in ARROW_PATHS.keys():
		var path = ARROW_PATHS[arrow_type]
		if ResourceLoader.exists(path):
			arrow_scenes[arrow_type] = load(path)
			print("[ArcherArrowSwitch] Loaded: %s" % path)
		else:
			push_warning("[ArcherArrowSwitch] Arrow scene not found: %s" % path)

func _execute() -> void:
	# Cycle to next arrow type
	current_arrow_type = (current_arrow_type + 1) % ArrowType.size() as ArrowType
	
	print("[Archer] Switched to: %s (%.0f%% damage)" % [
		ARROW_NAMES[current_arrow_type],
		DAMAGE_MULTIPLIERS[current_arrow_type] * 100
	])
	
	# Notify ProjectileSpawner
	_update_projectile_spawner()
	
	# Visual/audio feedback
	_show_switch_effect()

func _update_projectile_spawner() -> void:
	"""Update ProjectileSpawner với arrow type mới"""
	if not player or not player.has_node("ProjectileSpawner"):
		return
	
	var spawner = player.get_node("ProjectileSpawner")
	if current_arrow_type in arrow_scenes:
		spawner.cached_projectile_scene = arrow_scenes[current_arrow_type]

## Spawn arrow hiện tại
func spawn_current_arrow(direction: Vector2) -> Node:
	if current_arrow_type not in arrow_scenes:
		push_error("[ArcherArrowSwitch] No scene for arrow type: %d" % current_arrow_type)
		return null
	
	var arrow = arrow_scenes[current_arrow_type].instantiate()
	
	# Calculate damage
	var base_dmg = player.base_stats.base_damage if player and player.base_stats else 30.0
	var final_damage = base_dmg * DAMAGE_MULTIPLIERS[current_arrow_type]
	
	# Setup arrow
	if arrow.has_method("setup"):
		arrow.setup(direction, player, final_damage)
	else:
		arrow.direction = direction
		arrow.owner_player = player
		arrow.damage = final_damage
	
	return arrow

## Get current arrow info
func get_current_arrow_info() -> Dictionary:
	return {
		"type": current_arrow_type,
		"name": ARROW_NAMES[current_arrow_type],
		"damage_multiplier": DAMAGE_MULTIPLIERS[current_arrow_type],
		"scene": arrow_scenes.get(current_arrow_type)
	}

func get_current_arrow_scene() -> PackedScene:
	return arrow_scenes.get(current_arrow_type)

func get_current_damage_multiplier() -> float:
	return DAMAGE_MULTIPLIERS[current_arrow_type]

func _show_switch_effect() -> void:
	if not player or not player.has_node("Sprite2D"):
		return
	
	var sprite = player.get_node("Sprite2D")
	var tween = player.create_tween()
	
	# Color based on arrow type
	var flash_color: Color
	match current_arrow_type:
		ArrowType.NORMAL:
			flash_color = Color(1.0, 0.9, 0.5)  # Yellow
		ArrowType.AOE:
			flash_color = Color(1.0, 0.5, 0.2)  # Orange
		ArrowType.POISON:
			flash_color = Color(0.5, 1.0, 0.3)  # Green
	
	tween.tween_property(sprite, "modulate", flash_color, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
