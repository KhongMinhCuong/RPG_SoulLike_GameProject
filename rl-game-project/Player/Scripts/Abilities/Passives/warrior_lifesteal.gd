## WarriorLifesteal - Passive hút máu cho Warrior
## Hút máu scaling theo % HP hiện tại:
## - Trên 90% HP: 1% lifesteal
## - Dưới 30% HP: 15% lifesteal
## - Linear interpolation ở giữa
class_name WarriorLifesteal
extends "res://Player/Scripts/Abilities/passive_base.gd"

# === SCALING LIFESTEAL ===
var high_hp_threshold: float = 0.9  # Trên 90% HP
var low_hp_threshold: float = 0.3   # Dưới 30% HP
var high_hp_lifesteal: float = 0.01 # 1% lifesteal khi HP cao
var low_hp_lifesteal: float = 0.15  # 15% lifesteal khi HP thấp
var heal_per_hit_cap: float = 100.0 # Max heal mỗi hit

func _on_initialize() -> void:
	passive_name = "Bloodthirst"
	description = "Hút máu khi gây sát thương: 1% khi HP > 90%, tăng dần lên 15% khi HP < 30%"

## Override on_damage_dealt để hút máu
func _on_damage_dealt(damage: float, _target: Node) -> float:
	if not player or not is_active:
		return damage
	
	# Tính HP ratio
	var max_hp = player.get_max_health() if player.has_method("get_max_health") else 100.0
	var current_hp = 0.0
	if player.runtime_stats:
		current_hp = player.runtime_stats.current_health
	
	var hp_ratio = current_hp / max_hp if max_hp > 0 else 1.0
	
	# Tính lifesteal rate dựa trên HP ratio (linear interpolation)
	var lifesteal_rate: float
	if hp_ratio >= high_hp_threshold:
		# Trên 90% HP: 1%
		lifesteal_rate = high_hp_lifesteal
	elif hp_ratio <= low_hp_threshold:
		# Dưới 30% HP: 15%
		lifesteal_rate = low_hp_lifesteal
	else:
		# Linear interpolation: HP giảm từ 90% -> 30%, lifesteal tăng từ 1% -> 15%
		var t = (high_hp_threshold - hp_ratio) / (high_hp_threshold - low_hp_threshold)
		lifesteal_rate = lerp(high_hp_lifesteal, low_hp_lifesteal, t)
	
	# Tính heal amount
	var heal_amount = damage * lifesteal_rate
	heal_amount = min(heal_amount, heal_per_hit_cap)
	
	# Heal player
	if heal_amount > 0 and player.has_method("heal"):
		player.heal(heal_amount)
		print("[Warrior Passive] Lifesteal %.1f%% healed %.1f HP (HP: %.0f%%)" % [
			lifesteal_rate * 100, heal_amount, hp_ratio * 100
		])
		passive_effect_applied.emit(passive_name, heal_amount)
		
		# Visual effect khi hút nhiều máu
		if lifesteal_rate >= 0.10:
			_show_strong_lifesteal_effect()
	
	return damage  # Không modify damage, chỉ heal

func _show_strong_lifesteal_effect() -> void:
	"""Visual effect khi lifesteal mạnh (HP thấp)"""
	if player and player.has_node("Sprite2D"):
		var sprite = player.get_node("Sprite2D")
		# Red/blood flash khi lifesteal mạnh
		var tween = player.create_tween()
		tween.tween_property(sprite, "modulate", Color(1.4, 0.6, 0.6), 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
