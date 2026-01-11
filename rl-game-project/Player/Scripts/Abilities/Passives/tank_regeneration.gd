## TankRegeneration - Passive hồi máu cho Tank
## Hồi máu scaling theo % HP hiện tại:
## - Trên 90% HP: 0.5%/s
## - Dưới 30% HP: 5%/s  
## - Linear interpolation ở giữa
class_name TankRegeneration
extends "res://Player/Scripts/Abilities/passive_base.gd"

# === PASSIVE CONFIG ===
var regen_timer: float = 0.0
var regen_interval: float = 1.0  # Hồi mỗi 1 giây

# === SCALING REGEN ===
var high_hp_threshold: float = 0.9  # Trên 90% HP
var low_hp_threshold: float = 0.3   # Dưới 30% HP
var high_hp_regen: float = 0.005    # 0.5% HP/s khi HP cao
var low_hp_regen: float = 0.05      # 5% HP/s khi HP thấp

# === BONUS FROM ACTIVE ABILITY ===
var regen_multiplier: float = 1.0  # Có thể được buff bởi active ability

func _on_initialize() -> void:
	passive_name = "Undying Will"
	description = "Hồi máu tự động: 0.5%/s khi HP > 90%, tăng dần lên 5%/s khi HP < 30%"

func _on_update(delta: float) -> void:
	if not player or not is_active:
		return
	
	regen_timer += delta
	if regen_timer >= regen_interval:
		regen_timer -= regen_interval
		_apply_regen()

func _apply_regen() -> void:
	if not player:
		return
	
	var max_hp = player.get_max_health() if player.has_method("get_max_health") else 100.0
	var current_hp = 0.0
	
	if player.runtime_stats:
		current_hp = player.runtime_stats.current_health
	
	# Tính HP ratio
	var hp_ratio = current_hp / max_hp if max_hp > 0 else 1.0
	
	# Tính regen rate dựa trên HP ratio (linear interpolation)
	var regen_rate: float
	if hp_ratio >= high_hp_threshold:
		# Trên 90% HP: 0.5%/s
		regen_rate = high_hp_regen
	elif hp_ratio <= low_hp_threshold:
		# Dưới 30% HP: 5%/s
		regen_rate = low_hp_regen
	else:
		# Linear interpolation giữa 30% và 90% HP
		# Khi HP giảm từ 90% -> 30%, regen tăng từ 0.5% -> 5%
		var t = (high_hp_threshold - hp_ratio) / (high_hp_threshold - low_hp_threshold)
		regen_rate = lerp(high_hp_regen, low_hp_regen, t)
	
	# Apply multiplier từ active ability
	regen_rate *= regen_multiplier
	
	var heal_amount = max_hp * regen_rate
	
	# Chỉ heal nếu không full HP
	if current_hp < max_hp and player.has_method("heal"):
		player.heal(heal_amount)
		passive_effect_applied.emit(passive_name, heal_amount)

## Được gọi bởi active ability để buff regen
func set_regen_multiplier(multiplier: float) -> void:
	regen_multiplier = multiplier

func reset_regen_multiplier() -> void:
	regen_multiplier = 1.0

func _on_reset() -> void:
	regen_timer = 0.0
	regen_multiplier = 1.0
