## PlayerRuntimeStats - Quản lý stats runtime (health, cooldowns)
## Tách biệt khỏi base stats để dễ reset mỗi run/respawn
## NOTE: Buff/Debuff system sẽ được làm riêng sau
class_name PlayerRuntimeStats
extends Node

# === SIGNALS ===
signal health_changed(current: float, max_value: float)
signal health_depleted
signal cooldown_ready(ability_name: String)

# === REFERENCES ===
var stats: PlayerStats  # Reference tới base stats

# === HEALTH ===
var current_health: float = 100.0:
	set(value):
		var old = current_health
		current_health = clamp(value, 0.0, get_max_health())
		
		if current_health != old:
			health_changed.emit(current_health, get_max_health())
		
		if current_health <= 0.0 and old > 0.0:
			health_depleted.emit()

# === COOLDOWNS ===
var cooldowns: Dictionary = {
	"dash": 0.0,
	"special": 0.0,
	"parry": 0.0,
	"air_attack": 0.0,
}

## Thời gian cooldown cho mỗi ability (có thể config)
@export var dash_cooldown: float = 1.0
@export var special_cooldown: float = 5.0
@export var parry_cooldown: float = 2.0
@export var air_attack_cooldown: float = 0.5

# === INITIALIZATION ===

func initialize(player_stats: PlayerStats) -> void:
	"""Khởi tạo với reference tới base stats"""
	stats = player_stats
	reset_runtime_stats()
	
	# Connect signals từ base stats
	if stats:
		stats.stat_changed.connect(_on_base_stat_changed)
		stats.level_up.connect(_on_level_up)

func reset_runtime_stats() -> void:
	"""Reset tất cả runtime stats (respawn/new run)"""
	if stats:
		current_health = stats.max_health
	else:
		current_health = 100.0
	
	# Reset cooldowns
	for key in cooldowns.keys():
		cooldowns[key] = 0.0

# === UPDATE ===

func update(delta: float) -> void:
	"""Gọi mỗi frame để update cooldowns"""
	_update_cooldowns(delta)

func _update_cooldowns(delta: float) -> void:
	"""Update tất cả cooldowns"""
	for ability_name in cooldowns.keys():
		if cooldowns[ability_name] > 0.0:
			var old_cooldown = cooldowns[ability_name]
			cooldowns[ability_name] = max(0.0, cooldowns[ability_name] - delta)
			
			# Emit signal khi cooldown ready
			if old_cooldown > 0.0 and cooldowns[ability_name] <= 0.0:
				cooldown_ready.emit(ability_name)

# === HEALTH MANAGEMENT ===

func get_max_health() -> float:
	"""Lấy max HP từ base stats"""
	return stats.max_health if stats else 100.0

func heal(amount: float) -> void:
	"""Hồi máu"""
	current_health += amount

func take_damage(amount: float) -> float:
	"""Nhận damage (trừ defense). Return actual damage taken"""
	var actual_damage = stats.calculate_damage_taken(amount) if stats else amount
	
	current_health -= actual_damage
	return actual_damage

func heal_to_full() -> void:
	"""Hồi full máu"""
	current_health = get_max_health()

func is_alive() -> bool:
	"""Check còn sống không"""
	return current_health > 0.0

func get_health_percent() -> float:
	"""Trả về % máu hiện tại (0.0 - 1.0)"""
	var max_hp = get_max_health()
	return current_health / max_hp if max_hp > 0.0 else 0.0

# === COOLDOWN MANAGEMENT ===

func can_use_ability(ability_name: String) -> bool:
	"""Check ability có sẵn sàng không (cooldown = 0)"""
	return cooldowns.get(ability_name, 999.0) <= 0.0

func use_ability(ability_name: String) -> bool:
	"""Dùng ability và start cooldown. Return true nếu thành công"""
	if not can_use_ability(ability_name):
		return false
	
	match ability_name:
		"dash":
			cooldowns[ability_name] = dash_cooldown
		"special":
			cooldowns[ability_name] = special_cooldown
		"parry":
			cooldowns[ability_name] = parry_cooldown
		"air_attack":
			cooldowns[ability_name] = air_attack_cooldown
		_:
			push_warning("Unknown ability: " + ability_name)
			return false
	
	return true

func get_cooldown_percent(ability_name: String) -> float:
	"""Trả về % cooldown còn lại (0.0 = ready, 1.0 = just used)"""
	var current = cooldowns.get(ability_name, 0.0)
	
	var max_cooldown: float
	match ability_name:
		"dash": max_cooldown = dash_cooldown
		"special": max_cooldown = special_cooldown
		"parry": max_cooldown = parry_cooldown
		"air_attack": max_cooldown = air_attack_cooldown
		_: return 0.0
	
	return current / max_cooldown if max_cooldown > 0.0 else 0.0

func reset_cooldown(ability_name: String) -> void:
	"""Reset cooldown ngay lập tức (power-up effect)"""
	if ability_name in cooldowns:
		cooldowns[ability_name] = 0.0
		cooldown_ready.emit(ability_name)

func reset_all_cooldowns() -> void:
	"""Reset tất cả cooldowns (power-up effect)"""
	for ability_name in cooldowns.keys():
		reset_cooldown(ability_name)

# === STAT GETTERS ===

func get_move_speed() -> float:
	"""Lấy move speed từ base stats"""
	return stats.move_speed if stats else 200.0

func get_dash_speed() -> float:
	"""Lấy dash speed từ base stats"""
	return stats.dash_speed if stats else 400.0

func get_attack_speed_multiplier() -> float:
	"""Lấy attack speed multiplier từ base stats"""
	return stats.attack_speed_multiplier if stats else 1.0

func calculate_damage() -> float:
	"""Tính damage gây ra (có tính crit)"""
	return stats.calculate_damage_dealt() if stats else 10.0

# === SIGNAL HANDLERS ===

func _on_base_stat_changed(stat_name: String, old_value: float, new_value: float) -> void:
	"""Khi base stat thay đổi, update health nếu cần.
	Preserve current HP percentage relative to the OLD max when max_health changes.
	This prevents using the new max to compute percentage which keeps current HP unchanged.
	"""
	if stat_name == "max_health":
		var old_max := old_value
		var new_max := new_value
		if old_max > 0.0:
			var percent := current_health / old_max
			current_health = clamp(new_max * percent, 0.0, new_max)
		else:
			# Fallback: set to new max if old max was zero/unexpected
			current_health = new_max

func _on_level_up(new_level: int) -> void:
	"""Khi level up, hồi full máu và reset cooldowns"""
	print("[RuntimeStats] Level up to ", new_level, " - healing to full!")
	heal_to_full()
	reset_all_cooldowns()

# === UTILITY ===

func get_stats_summary() -> Dictionary:
	"""Trả về dictionary chứa runtime stats"""
	return {
		"current_health": current_health,
		"max_health": get_max_health(),
		"health_percent": get_health_percent(),
		
		"dash_cooldown": cooldowns.get("dash", 0.0),
		"special_cooldown": cooldowns.get("special", 0.0),
		"parry_cooldown": cooldowns.get("parry", 0.0),
		"air_attack_cooldown": cooldowns.get("air_attack", 0.0),
	}
