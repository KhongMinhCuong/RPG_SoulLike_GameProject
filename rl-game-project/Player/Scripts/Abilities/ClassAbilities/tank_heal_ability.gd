## TankFortify - Fortify ability cho Tank
## Tăng 30% giáp và tăng hiệu quả hồi máu trong 5 giây
## Scaling theo level: +10% hiệu ứng, +0.5s duration, +0.5s cooldown mỗi level
class_name TankHealAbility
extends "res://Player/Scripts/Abilities/ability_base.gd"

# === BASE CONFIG ===
var base_armor_bonus: float = 0.30  # 30% armor bonus
var base_heal_bonus: float = 0.30   # 30% healing bonus
var base_duration: float = 5.0      # 5 seconds
var base_cooldown: float = 10.0     # 10 seconds base cooldown

# === SCALING PER LEVEL ===
var bonus_per_level: float = 0.10   # +10% per level
var duration_per_level: float = 0.5 # +0.5s duration per level
var cooldown_per_level: float = 0.5 # +0.5s cooldown per level

# === STATE ===
var is_buff_active: bool = false
var buff_timer: float = 0.0
var current_armor_bonus: float = 0.0
var current_heal_bonus: float = 0.0
var buff_tween: Tween = null  # Reference to kill tween when buff ends

# === PASSIVE REFERENCE ===
var regen_passive: PassiveBase = null

func _on_initialize() -> void:
	ability_name = "Fortify"
	description = "Tăng 30% giáp và hiệu quả hồi máu trong 5 giây. Scaling theo level."
	cooldown = base_cooldown
	mana_cost = 0.0
	
	# Update cooldown theo level
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
		"armor_bonus": base_armor_bonus + level_bonus,
		"heal_bonus": base_heal_bonus + level_bonus,
		"duration": base_duration + duration_bonus
	}

func _execute() -> void:
	if not player:
		return
	
	# Update stats trước khi execute
	_update_stats_for_level()
	
	var scaled = _get_scaled_values()
	current_armor_bonus = scaled.armor_bonus
	current_heal_bonus = scaled.heal_bonus
	
	is_buff_active = true
	buff_timer = scaled.duration
	
	# Apply armor bonus
	if player.runtime_stats and player.runtime_stats.has_method("add_armor_multiplier"):
		player.runtime_stats.add_armor_multiplier(current_armor_bonus)
	elif player.base_stats:
		# Fallback: modify defense directly
		player.base_stats.defense_bonus += int(current_armor_bonus * 100)
	
	# Find và buff regen passive
	_find_and_buff_regen_passive()
	
	print("[Tank] Fortify activated! Armor +%.0f%%, Heal +%.0f%% for %.1fs (Level %d)" % [
		current_armor_bonus * 100, 
		current_heal_bonus * 100, 
		scaled.duration,
		player.base_stats.current_level if player.base_stats else 1
	])
	
	# Visual feedback
	_show_buff_effect()

func _find_and_buff_regen_passive() -> void:
	"""Tìm và buff passive regen"""
	if not player.has_node("AbilityManager"):
		return
	
	var ability_mgr = player.get_node("AbilityManager")
	for passive in ability_mgr.passives:
		if passive is TankRegeneration:
			regen_passive = passive
			passive.set_regen_multiplier(1.0 + current_heal_bonus)
			break

func _on_update(delta: float) -> void:
	if not is_buff_active:
		return
	
	buff_timer -= delta
	if buff_timer <= 0.0:
		_end_buff()

func has_buff() -> bool:
	return is_buff_active

func get_armor_bonus() -> float:
	return current_armor_bonus if is_buff_active else 0.0

func _end_buff() -> void:
	is_buff_active = false
	buff_timer = 0.0
	
	# Remove armor bonus
	if player and player.runtime_stats and player.runtime_stats.has_method("remove_armor_multiplier"):
		player.runtime_stats.remove_armor_multiplier(current_armor_bonus)
	elif player and player.base_stats:
		player.base_stats.defense_bonus -= int(current_armor_bonus * 100)
	
	# Reset regen passive multiplier
	if regen_passive:
		regen_passive.reset_regen_multiplier()
		regen_passive = null
	
	current_armor_bonus = 0.0
	current_heal_bonus = 0.0
	
	print("[Tank] Fortify ended")
	
	# Kill tween and remove visual effect
	if buff_tween and buff_tween.is_valid():
		buff_tween.kill()
		buff_tween = null
	if player and player.has_node("Sprite2D"):
		player.get_node("Sprite2D").modulate = Color.WHITE

func _show_buff_effect() -> void:
	if player and player.has_node("Sprite2D"):
		var sprite = player.get_node("Sprite2D")
		# Golden shield effect
		sprite.modulate = Color(1.0, 0.9, 0.6, 1.0)
		
		# Kill existing tween if any
		if buff_tween and buff_tween.is_valid():
			buff_tween.kill()
		
		# Pulsing effect
		var scaled = _get_scaled_values()
		buff_tween = player.create_tween()
		buff_tween.set_loops(int(scaled.duration / 0.5))
		buff_tween.tween_property(sprite, "modulate", Color(1.2, 1.0, 0.7), 0.25)
		buff_tween.tween_property(sprite, "modulate", Color(1.0, 0.9, 0.6), 0.25)

func _on_reset() -> void:
	if is_buff_active:
		_end_buff()
	is_buff_active = false
	buff_timer = 0.0
	current_armor_bonus = 0.0
	current_heal_bonus = 0.0
