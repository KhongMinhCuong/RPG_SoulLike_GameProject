## PlayerStats - Hệ thống chỉ số và level up cho Roguelike
## Quản lý: Level, Experience, Base Stats, Calculated Stats
## Độc lập với Player logic - chỉ data và calculations
class_name PlayerStats
extends Resource

# === SIGNALS ===
signal level_up(new_level: int)
signal experience_gained(amount: int, total: int)
signal stat_changed(stat_name: String, old_value: float, new_value: float)

# === LEVEL & EXPERIENCE ===
@export_group("Level System")
@export var current_level: int = 1:
	set(value):
		var old = current_level
		current_level = max(1, value)
		if old != current_level:
			level_up.emit(current_level)
			_recalculate_all_stats()

@export var current_experience: int = 0:
	set(value):
		current_experience = max(0, value)
		_check_level_up()

@export var experience_to_next_level: int = 100

## Công thức tính exp cần cho level tiếp theo: base * (level ^ exponent)
@export var exp_scaling_base: float = 100.0
@export var exp_scaling_exponent: float = 1.5

# === BASE ATTRIBUTES ===
@export_group("Base Attributes")
## Sức mạnh - ảnh hưởng damage
@export var strength: int = 10:
	set(value):
		var old = strength
		strength = max(1, value)
		if old != strength:
			stat_changed.emit("strength", old, strength)
			_recalculate_damage_stats()

## Sức bền - ảnh hưởng HP và defense
@export var vitality: int = 10:
	set(value):
		var old = vitality
		vitality = max(1, value)
		if old != vitality:
			stat_changed.emit("vitality", old, vitality)
			_recalculate_defensive_stats()

## Nhanh nhẹn - ảnh hưởng speed và attack speed
@export var agility: int = 10:
	set(value):
		var old = agility
		agility = max(1, value)
		if old != agility:
			stat_changed.emit("agility", old, agility)
			_recalculate_speed_stats()

## May mắn - ảnh hưởng crit chance và drop rate
@export var luck: int = 10:
	set(value):
		var old = luck
		luck = max(1, value)
		if old != luck:
			stat_changed.emit("luck", old, luck)
			_recalculate_luck_stats()

# === STAT POINTS ===
@export var unspent_stat_points: int = 0

# === CALCULATED STATS (Read-only) ===
## Combat Stats
var max_health: float = 100.0
var base_damage: float = 10.0
var defense: float = 5.0
var critical_chance: float = 0.05  # 5% base
var critical_multiplier: float = 1.5  # 150% damage on crit

## Movement Stats
var move_speed: float = 200.0
var attack_speed_multiplier: float = 1.0
var dash_speed: float = 400.0

## Other Stats
var drop_rate_multiplier: float = 1.0

# === STAT SCALING FORMULAS ===
@export_group("Stat Scaling Formulas")
## HP = base + (vitality * hp_per_vitality)
@export var base_health: float = 80.0
@export var hp_per_vitality: float = 15.0

## Damage = base + (strength * damage_per_strength)
@export var base_attack: float = 8.0
@export var damage_per_strength: float = 2.0

## Defense = base + (vitality * defense_per_vitality)
@export var base_defense: float = 3.0
@export var defense_per_vitality: float = 1.2

## Speed = base + (agility * speed_per_agility)
@export var base_speed: float = 180.0
@export var speed_per_agility: float = 3.0

## Attack Speed = 1.0 + (agility * attack_speed_per_agility)
@export var attack_speed_per_agility: float = 0.02  # 2% per point

## Crit Chance = base + (luck * crit_per_luck)
@export var base_crit_chance: float = 0.05  # 5%
@export var crit_per_luck: float = 0.005  # 0.5% per point

## Drop Rate = 1.0 + (luck * drop_per_luck)
@export var drop_per_luck: float = 0.02  # 2% per point

# === INITIALIZATION ===
func _init() -> void:
	_recalculate_all_stats()
	_update_exp_requirement()

# === EXPERIENCE & LEVELING ===

func add_experience(amount: int) -> void:
	"""Thêm experience và auto level up nếu đủ"""
	if amount <= 0:
		return
	
	current_experience += amount
	experience_gained.emit(amount, current_experience)

func _check_level_up() -> void:
	"""Kiểm tra và tự động level up nếu đủ exp"""
	while current_experience >= experience_to_next_level:
		current_experience -= experience_to_next_level
		current_level += 1
		unspent_stat_points += 3  # 3 stat points mỗi level
		_update_exp_requirement()

func _update_exp_requirement() -> void:
	"""Tính exp cần cho level tiếp theo"""
	experience_to_next_level = int(exp_scaling_base * pow(current_level, exp_scaling_exponent))

func get_experience_progress() -> float:
	"""Trả về % exp hiện tại (0.0 - 1.0)"""
	if experience_to_next_level <= 0:
		return 1.0
	return float(current_experience) / float(experience_to_next_level)

# === STAT MANAGEMENT ===

func can_spend_stat_point() -> bool:
	"""Kiểm tra có stat point để spend không"""
	return unspent_stat_points > 0

func increase_stat(stat_name: String) -> bool:
	"""Tăng một stat bằng stat point. Return true nếu thành công"""
	if not can_spend_stat_point():
		return false
	
	match stat_name.to_lower():
		"strength", "str":
			strength += 1
			unspent_stat_points -= 1
			return true
		"vitality", "vit":
			vitality += 1
			unspent_stat_points -= 1
			return true
		"agility", "agi":
			agility += 1
			unspent_stat_points -= 1
			return true
		"luck", "lck":
			luck += 1
			unspent_stat_points -= 1
			return true
		_:
			push_error("Unknown stat name: " + stat_name)
			return false

# === STAT CALCULATIONS ===

func _recalculate_all_stats() -> void:
	"""Tính lại tất cả stats từ base attributes"""
	_recalculate_damage_stats()
	_recalculate_defensive_stats()
	_recalculate_speed_stats()
	_recalculate_luck_stats()

func _recalculate_damage_stats() -> void:
	"""Tính lại damage stats từ strength"""
	base_damage = base_attack + (strength * damage_per_strength)

func _recalculate_defensive_stats() -> void:
	"""Tính lại HP và defense từ vitality"""
	max_health = base_health + (vitality * hp_per_vitality)
	defense = base_defense + (vitality * defense_per_vitality)

func _recalculate_speed_stats() -> void:
	"""Tính lại speed stats từ agility"""
	move_speed = base_speed + (agility * speed_per_agility)
	attack_speed_multiplier = 1.0 + (agility * attack_speed_per_agility)
	dash_speed = move_speed * 2.0  # Dash = 2x movement speed

func _recalculate_luck_stats() -> void:
	"""Tính lại luck stats"""
	critical_chance = base_crit_chance + (luck * crit_per_luck)
	drop_rate_multiplier = 1.0 + (luck * drop_per_luck)

# === COMBAT CALCULATIONS ===

func calculate_damage_dealt(base_dmg: float = 0.0) -> float:
	"""Tính damage gây ra (có xét crit)"""
	var final_damage = base_dmg if base_dmg > 0.0 else base_damage
	
	# Roll for critical hit
	if randf() < critical_chance:
		final_damage *= critical_multiplier
	
	return final_damage

func calculate_damage_taken(incoming_damage: float) -> float:
	"""Tính damage nhận vào sau khi trừ defense"""
	var reduced_damage = incoming_damage - defense
	return max(1.0, reduced_damage)  # Tối thiểu 1 damage

# === UTILITY METHODS ===

func get_stat_summary() -> Dictionary:
	"""Trả về dictionary chứa tất cả stats"""
	return {
		"level": current_level,
		"experience": current_experience,
		"exp_to_next": experience_to_next_level,
		"unspent_points": unspent_stat_points,
		
		"strength": strength,
		"vitality": vitality,
		"agility": agility,
		"luck": luck,
		
		"max_health": max_health,
		"base_damage": base_damage,
		"defense": defense,
		"move_speed": move_speed,
		"attack_speed": attack_speed_multiplier,
		"crit_chance": critical_chance,
		"crit_multiplier": critical_multiplier,
		"drop_rate": drop_rate_multiplier,
	}

func reset_to_level_one() -> void:
	"""Reset về level 1 (cho new game+)"""
	current_level = 1
	current_experience = 0
	strength = 10
	vitality = 10
	agility = 10
	luck = 10
	unspent_stat_points = 0
	_recalculate_all_stats()
	_update_exp_requirement()

func save_to_dict() -> Dictionary:
	"""Lưu stats ra dictionary để save game"""
	return {
		"level": current_level,
		"exp": current_experience,
		"unspent_points": unspent_stat_points,
		"str": strength,
		"vit": vitality,
		"agi": agility,
		"lck": luck,
	}

func load_from_dict(data: Dictionary) -> void:
	"""Load stats từ dictionary (save game)"""
	current_level = data.get("level", 1)
	current_experience = data.get("exp", 0)
	unspent_stat_points = data.get("unspent_points", 0)
	strength = data.get("str", 10)
	vitality = data.get("vit", 10)
	agility = data.get("agi", 10)
	luck = data.get("lck", 10)
	_recalculate_all_stats()
	_update_exp_requirement()
