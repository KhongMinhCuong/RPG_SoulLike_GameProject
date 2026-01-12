## WarriorBattleFury - Battle Fury ability cho Warrior
## Tăng 30% damage và giảm cooldown các ability trong 10 giây
## Scaling: +2.5% hiệu ứng, +0.5s duration, +0.5s cooldown mỗi level
class_name WarriorDamageBoost
extends "res://Player/Scripts/Abilities/ability_base.gd"

# === BASE CONFIG ===
var base_damage_bonus: float = 0.30   # 30% damage bonus
var base_cooldown_reduction: float = 0.30  # 30% cooldown reduction
var base_duration: float = 10.0       # 10 seconds
var base_cooldown: float = 20.0       # 20 seconds base cooldown

# === SCALING PER LEVEL ===
var bonus_per_level: float = 0.025    # +2.5% per level
var duration_per_level: float = 0.5   # +0.5s duration per level
var cooldown_per_level: float = 0.5   # +0.5s cooldown per level

# === STATE ===
var is_buff_active: bool = false
var buff_timer: float = 0.0
var current_damage_bonus: float = 0.0
var current_cd_reduction: float = 0.0
var buff_tween: Tween = null  # Reference to kill tween when buff ends

func _on_initialize() -> void:
	ability_name = "Battle Fury"
	description = "Tăng 30% damage và giảm 30% cooldown trong 10 giây. Scaling theo level."
	cooldown = base_cooldown
	mana_cost = 0.0
	
	_update_stats_for_level()

func _update_stats_for_level() -> void:
	"""Cập nhật stats theo level của player"""
	var player_level = 1
	if player and player.base_stats:
		player_level = player.base_stats.current_level
	
	# Cooldown tăng theo level
	cooldown = base_cooldown + (player_level - 1) * cooldown_per_level

func _get_scaled_values() -> Dictionary:
	"""Tính toán giá trị đã scale theo level"""
	var player_level = 1
	if player and player.base_stats:
		player_level = player.base_stats.current_level
	
	var level_bonus = (player_level - 1) * bonus_per_level
	var duration_bonus = (player_level - 1) * duration_per_level
	
	return {
		"damage_bonus": base_damage_bonus + level_bonus,
		"cd_reduction": base_cooldown_reduction + level_bonus,
		"duration": base_duration + duration_bonus
	}

func _execute() -> void:
	if not player:
		return
	
	_update_stats_for_level()
	
	var scaled = _get_scaled_values()
	current_damage_bonus = scaled.damage_bonus
	current_cd_reduction = scaled.cd_reduction
	
	is_buff_active = true
	buff_timer = scaled.duration
	
	# Apply damage bonus to player stats
	if player.base_stats:
		player.base_stats.damage_multiplier += current_damage_bonus
	
	# Apply cooldown reduction to all abilities
	_apply_cooldown_reduction()
	
	print("[Warrior] Battle Fury activated! Damage +%.0f%%, CD -%.0f%% for %.1fs (Level %d)" % [
		current_damage_bonus * 100,
		current_cd_reduction * 100,
		scaled.duration,
		player.base_stats.current_level if player.base_stats else 1
	])
	
	_show_buff_effect()

func _apply_cooldown_reduction() -> void:
	"""Giảm cooldown hiện tại của tất cả abilities"""
	if not player.has_node("AbilityManager"):
		return
	
	var ability_mgr = player.get_node("AbilityManager")
	for ability in ability_mgr.abilities.values():
		if ability != self:  # Không giảm CD của chính mình
			ability.current_cooldown *= (1.0 - current_cd_reduction)

func _on_update(delta: float) -> void:
	if not is_buff_active:
		return
	
	buff_timer -= delta
	if buff_timer <= 0.0:
		_end_buff()

func has_buff() -> bool:
	return is_buff_active

func get_damage_multiplier() -> float:
	"""Trả về damage multiplier để sử dụng trong combat"""
	if not is_buff_active:
		return 1.0
	return 1.0 + current_damage_bonus

func _end_buff() -> void:
	is_buff_active = false
	buff_timer = 0.0
	
	# Remove damage bonus
	if player and player.base_stats:
		player.base_stats.damage_multiplier -= current_damage_bonus
	
	current_damage_bonus = 0.0
	current_cd_reduction = 0.0
	
	print("[Warrior] Battle Fury ended")
	
	# Kill tween and remove visual
	if buff_tween and buff_tween.is_valid():
		buff_tween.kill()
		buff_tween = null
	if player and player.has_node("Sprite2D"):
		player.get_node("Sprite2D").modulate = Color.WHITE

func _show_buff_effect() -> void:
	if player and player.has_node("Sprite2D"):
		var sprite = player.get_node("Sprite2D")
		# Red/orange fury effect
		sprite.modulate = Color(1.3, 0.8, 0.6, 1.0)
		
		# Kill existing tween if any
		if buff_tween and buff_tween.is_valid():
			buff_tween.kill()
		
		var scaled = _get_scaled_values()
		buff_tween = player.create_tween()
		buff_tween.set_loops(int(scaled.duration / 0.4))
		buff_tween.tween_property(sprite, "modulate", Color(1.5, 0.7, 0.5), 0.2)
		buff_tween.tween_property(sprite, "modulate", Color(1.3, 0.8, 0.6), 0.2)

func _on_reset() -> void:
	if is_buff_active:
		_end_buff()
	is_buff_active = false
	buff_timer = 0.0
	current_damage_bonus = 0.0
	current_cd_reduction = 0.0
