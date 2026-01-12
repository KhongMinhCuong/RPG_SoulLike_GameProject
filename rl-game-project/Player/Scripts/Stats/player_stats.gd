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
@export var current_level: int = 1

@export var current_experience: int = 0

@export var experience_to_next_level: int = 100

## Công thức tính exp cần cho level tiếp theo: base * (level ^ exponent)
@export var exp_scaling_base: float = 100.0
@export var exp_scaling_exponent: float = 1.5

# === BASE ATTRIBUTES ===
@export_group("Base Attributes")
## Sức mạnh - ảnh hưởng damage
@export var strength: int = 0

## Sức bền - ảnh hưởng HP và defense
@export var vitality: int = 0

## Khéo léo - ảnh hưởng attack speed, cooldown, crit chance
@export var dexterity: int = 0

## Tốc độ di chuyển - ảnh hưởng move speed và dash speed
@export var movement_speed: int = 0

## May mắn - ảnh hưởng drop rate và buff may mắn
@export var luck: int = 0

# === STAT POINTS (Dual Point System) ===
@export var basic_stat_points: int = 0  # 2 điểm/level cho stats cơ bản
@export var special_upgrade_points: int = 0  # 1 điểm/level cho mini-boosts

# === SOFT CAP CONFIGURATION ===
@export_group("Diminishing Returns System")
@export var strength_max_value: float = 100.0
@export var strength_scale: float = 50.0  # Hệ số giảm lợi ích

@export var vitality_max_value: float = 100.0
@export var vitality_scale: float = 50.0

@export var dexterity_max_value: float = 100.0
@export var dexterity_scale: float = 50.0

@export var movement_speed_max_value: float = 100.0
@export var movement_speed_scale: float = 50.0

@export var luck_max_value: float = 100.0
@export var luck_scale: float = 50.0

# === SPECIAL UPGRADES (Mini-Boosts) ===
var active_special_upgrades: Array[Dictionary] = []  # Lưu các upgrade đã chọn

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
var cooldown_reduction: float = 0.0  # Giảm cooldown % từ dexterity

## Other Stats
var damage_reduction: float = 0.0  # % giảm sát thương nhận vào
var hp_regen_per_second: float = 0.0  # HP hồi mỗi giây

## Ability Buff Modifiers (temporary bonuses from abilities)
var damage_multiplier: float = 1.0  # Multiplier cho damage (từ abilities như Battle Fury)
var defense_bonus: int = 0  # Bonus defense (từ abilities như Fortify)

# === STAT SCALING FORMULAS ===
@export_group("Stat Scaling Formulas")
## HP = base + (vitality * hp_per_vitality)
@export var base_health: float = 30.0
@export var hp_per_vitality: float = 15.0

## Damage = base + (strength * damage_per_strength)
@export var base_attack: float = 8.0
@export var damage_per_strength: float = 2.0

## Defense = base + (vitality * defense_per_vitality)
@export var base_defense: float = 3.0
@export var defense_per_vitality: float = 1.2

## Move Speed = base + (movement_speed * move_speed_per_point)
@export var base_speed: float = 180.0
@export var move_speed_per_point: float = 3.0

## Attack Speed = 1.0 + (dexterity * attack_speed_per_dex)
@export var attack_speed_per_dex: float = 0.02  # 2% per point

## Cooldown Reduction = dexterity * cooldown_per_dex
@export var cooldown_per_dex: float = 0.01  # 1% per point

## Crit Chance = base + (luck * crit_per_luck)
@export var base_crit_chance: float = 0.05  # 5%
@export var crit_per_luck: float = 0.01  # 1% per point

## Crit Multiplier = base + (luck * crit_mult_per_luck)
@export var base_crit_multiplier: float = 1.5  # 150% base
@export var crit_mult_per_luck: float = 0.02  # +2% crit damage per luck

# === INITIALIZATION ===
func _init() -> void:
	_recalculate_all_stats()
	_update_exp_requirement()

# Helper methods to change properties so signals and recalculations run
func set_level(value: int) -> void:
	var old = current_level
	current_level = max(1, value)
	if old != current_level:
		level_up.emit(current_level)
		_recalculate_all_stats()

func add_experience(amount: int) -> void:
	"""Thêm experience và auto level up nếu đủ"""
	if amount <= 0:
		return
	current_experience = max(0, current_experience + amount)
	experience_gained.emit(amount, current_experience)
	_check_level_up()

func change_strength(delta: int) -> void:
	var old = strength
	strength = max(0, strength + delta)
	if old != strength:
		stat_changed.emit("strength", old, strength)
		_recalculate_damage_stats()

func change_vitality(delta: int) -> void:
	var old = vitality
	vitality = max(0, vitality + delta)
	if old != vitality:
		stat_changed.emit("vitality", old, vitality)
		_recalculate_defensive_stats()

func change_dexterity(delta: int) -> void:
	var old = dexterity
	dexterity = max(0, dexterity + delta)
	if old != dexterity:
		stat_changed.emit("dexterity", old, dexterity)
		_recalculate_speed_stats()
		_recalculate_luck_stats()  # Crit chance từ dexterity

func change_movement_speed(delta: int) -> void:
	var old = movement_speed
	movement_speed = max(0, movement_speed + delta)
	if old != movement_speed:
		stat_changed.emit("movement_speed", old, movement_speed)
		_recalculate_speed_stats()

func change_luck(delta: int) -> void:
	var old = luck
	luck = max(0, luck + delta)
	if old != luck:
		stat_changed.emit("luck", old, luck)
		_recalculate_luck_stats()

# === EXPERIENCE & LEVELING ===

## Tính giá trị hiệu quả với Diminishing Returns
func effective_stat(stat_value: int, max_value: float, scale: float) -> float:
	"""Tính giá trị hiệu quả của stat theo công thức Diminishing Returns
	Công thức: EffectiveStat = (x * maxValue) / (x + scale)
	"""
	if stat_value <= 0:
		return 0.0
	return (stat_value * max_value) / (stat_value + scale)

func _check_level_up() -> void:
	"""Kiểm tra và tự động level up nếu đủ exp"""
	while current_experience >= experience_to_next_level:
		current_experience -= experience_to_next_level
		# Use set_level helper to ensure signals/recalcs
		set_level(current_level + 1)
		# Dual point system: 2 basic + 1 special
		basic_stat_points += 2
		special_upgrade_points += 1
		stat_changed.emit("basic_stat_points", basic_stat_points - 2, basic_stat_points)
		stat_changed.emit("special_upgrade_points", special_upgrade_points - 1, special_upgrade_points)
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

func can_spend_basic_point() -> bool:
	"""Kiểm tra có basic stat point để spend không"""
	return basic_stat_points > 0

func can_spend_special_point() -> bool:
	"""Kiểm tra có special upgrade point để spend không"""
	return special_upgrade_points > 0

func increase_stat(stat_name: String) -> bool:
	"""Tăng một stat bằng basic stat point. Return true nếu thành công"""
	if not can_spend_basic_point():
		return false
	
	match stat_name.to_lower():
		"strength", "str":
			change_strength(1)
			var old_points = basic_stat_points
			basic_stat_points = max(0, basic_stat_points - 1)
			stat_changed.emit("basic_stat_points", old_points, basic_stat_points)
			return true
		"vitality", "vit":
			change_vitality(1)
			var old_points = basic_stat_points
			basic_stat_points = max(0, basic_stat_points - 1)
			stat_changed.emit("basic_stat_points", old_points, basic_stat_points)
			return true
		"dexterity", "dex":
			change_dexterity(1)
			var old_points = basic_stat_points
			basic_stat_points = max(0, basic_stat_points - 1)
			stat_changed.emit("basic_stat_points", old_points, basic_stat_points)
			return true
		"movement_speed", "move", "spd":
			change_movement_speed(1)
			var old_points = basic_stat_points
			basic_stat_points = max(0, basic_stat_points - 1)
			stat_changed.emit("basic_stat_points", old_points, basic_stat_points)
			return true
		"luck", "lck":
			change_luck(1)
			var old_points = basic_stat_points
			basic_stat_points = max(0, basic_stat_points - 1)
			stat_changed.emit("basic_stat_points", old_points, basic_stat_points)
			return true
		_:
			push_error("Unknown stat name: " + stat_name)
			return false

func add_basic_stat_points(amount: int) -> void:
	"""Thêm `amount` basic stat points (dùng cho cheat / debug / rewards)
	Emit `stat_changed` cho `basic_stat_points` để UI có thể cập nhật ngay.
	"""
	if amount == 0:
		return
	var old = basic_stat_points
	basic_stat_points = max(0, basic_stat_points + amount)
	if old != basic_stat_points:
		stat_changed.emit("basic_stat_points", old, basic_stat_points)

func add_special_upgrade_points(amount: int) -> void:
	"""Thêm `amount` special upgrade points"""
	if amount == 0:
		return
	var old = special_upgrade_points
	special_upgrade_points = max(0, special_upgrade_points + amount)
	if old != special_upgrade_points:
		stat_changed.emit("special_upgrade_points", old, special_upgrade_points)

# === SPECIAL UPGRADES (Mini-Boosts) ===

enum SpecialUpgradeType {
	DAMAGE_BOOST,       # +5% damage
	HP_REGEN,           # +10% HP regen per second
	CRIT_CHANCE_BOOST,  # +0.5% crit chance
	DAMAGE_REDUCTION,   # -3% damage taken
	COOLDOWN_BOOST,     # -5% cooldown
	MOVE_SPEED_BOOST,   # +5% move speed
	ATTACK_SPEED_BOOST, # +5% attack speed
}

func apply_special_upgrade(upgrade_type: SpecialUpgradeType) -> bool:
	"""Áp dụng một special upgrade và trừ điểm"""
	if not can_spend_special_point():
		return false
	
	var upgrade_data = {
		"type": upgrade_type,
		"level": current_level,
	}
	
	# Apply buff theo loại upgrade
	match upgrade_type:
		SpecialUpgradeType.DAMAGE_BOOST:
			upgrade_data["bonus"] = 0.05
		SpecialUpgradeType.HP_REGEN:
			upgrade_data["bonus"] = 0.1
		SpecialUpgradeType.CRIT_CHANCE_BOOST:
			upgrade_data["bonus"] = 0.005
		SpecialUpgradeType.DAMAGE_REDUCTION:
			upgrade_data["bonus"] = 0.03
		SpecialUpgradeType.COOLDOWN_BOOST:
			upgrade_data["bonus"] = 0.05
		SpecialUpgradeType.MOVE_SPEED_BOOST:
			upgrade_data["bonus"] = 0.05
		SpecialUpgradeType.ATTACK_SPEED_BOOST:
			upgrade_data["bonus"] = 0.05
	
	active_special_upgrades.append(upgrade_data)
	
	var old_points = special_upgrade_points
	special_upgrade_points = max(0, special_upgrade_points - 1)
	stat_changed.emit("special_upgrade_points", old_points, special_upgrade_points)
	
	# Tính lại tất cả stats vì upgrade ảnh hưởng
	_recalculate_all_stats()
	return true

func get_special_upgrade_bonus(upgrade_type: SpecialUpgradeType) -> float:
	"""Tính tổng bonus từ tất cả special upgrades của loại này"""
	var total = 0.0
	for upgrade in active_special_upgrades:
		if upgrade.get("type") == upgrade_type:
			total += upgrade.get("bonus", 0.0)
	return total

# === STAT CALCULATIONS ===

func _recalculate_all_stats() -> void:
	"""Tính lại tất cả stats từ base attributes"""
	_recalculate_damage_stats()
	_recalculate_defensive_stats()
	_recalculate_speed_stats()
	_recalculate_luck_stats()

func _recalculate_damage_stats() -> void:
	"""Tính lại damage stats từ strength"""
	var old = base_damage
	var eff_str = effective_stat(strength, strength_max_value, strength_scale)
	base_damage = base_attack + (eff_str * damage_per_strength)
	
	# Áp dụng damage boost từ special upgrades
	var damage_boost = get_special_upgrade_bonus(SpecialUpgradeType.DAMAGE_BOOST)
	base_damage *= (1.0 + damage_boost)
	
	if old != base_damage:
		stat_changed.emit("base_damage", old, base_damage)

func _recalculate_defensive_stats() -> void:
	"""Tính lại HP và defense từ vitality"""
	var old_max = max_health
	var old_def = defense
	var old_dmg_red = damage_reduction
	var old_regen = hp_regen_per_second
	
	var eff_vit = effective_stat(vitality, vitality_max_value, vitality_scale)
	max_health = base_health + (eff_vit * hp_per_vitality)
	defense = base_defense + (eff_vit * defense_per_vitality)
	
	# Áp dụng damage reduction từ special upgrades
	damage_reduction = get_special_upgrade_bonus(SpecialUpgradeType.DAMAGE_REDUCTION)
	
	# Áp dụng HP regen từ special upgrades
	hp_regen_per_second = max_health * get_special_upgrade_bonus(SpecialUpgradeType.HP_REGEN)
	
	if old_max != max_health:
		stat_changed.emit("max_health", old_max, max_health)
	if old_def != defense:
		stat_changed.emit("defense", old_def, defense)
	if old_dmg_red != damage_reduction:
		stat_changed.emit("damage_reduction", old_dmg_red, damage_reduction)
	if old_regen != hp_regen_per_second:
		stat_changed.emit("hp_regen_per_second", old_regen, hp_regen_per_second)

func _recalculate_speed_stats() -> void:
	"""Tính lại speed stats từ dexterity và movement_speed"""
	var old_move = move_speed
	var old_atk_spd = attack_speed_multiplier
	var old_dash = dash_speed
	var old_cd_red = cooldown_reduction
	
	var eff_dex = effective_stat(dexterity, dexterity_max_value, dexterity_scale)
	var eff_mov = effective_stat(movement_speed, movement_speed_max_value, movement_speed_scale)
	
	# Movement speed từ movement_speed stat
	move_speed = base_speed + (eff_mov * move_speed_per_point)
	# Áp dụng move speed boost từ special upgrades
	var move_boost = get_special_upgrade_bonus(SpecialUpgradeType.MOVE_SPEED_BOOST)
	move_speed *= (1.0 + move_boost)
	
	# Attack speed từ dexterity
	attack_speed_multiplier = 1.0 + (eff_dex * attack_speed_per_dex)
	# Áp dụng attack speed boost từ special upgrades
	var atk_spd_boost = get_special_upgrade_bonus(SpecialUpgradeType.ATTACK_SPEED_BOOST)
	attack_speed_multiplier *= (1.0 + atk_spd_boost)
	
	# Dash = 2x movement speed
	dash_speed = move_speed * 2.0
	
	# Cooldown reduction từ dexterity
	cooldown_reduction = eff_dex * cooldown_per_dex
	# Áp dụng cooldown boost từ special upgrades
	cooldown_reduction += get_special_upgrade_bonus(SpecialUpgradeType.COOLDOWN_BOOST)
	
	if old_move != move_speed:
		stat_changed.emit("move_speed", old_move, move_speed)
	if old_atk_spd != attack_speed_multiplier:
		stat_changed.emit("attack_speed_multiplier", old_atk_spd, attack_speed_multiplier)
	if old_dash != dash_speed:
		stat_changed.emit("dash_speed", old_dash, dash_speed)
	if old_cd_red != cooldown_reduction:
		stat_changed.emit("cooldown_reduction", old_cd_red, cooldown_reduction)

func _recalculate_luck_stats() -> void:
	"""Tính lại luck stats: crit chance và crit multiplier"""
	var old_crit = critical_chance
	var old_crit_mult = critical_multiplier
	
	var eff_luck = effective_stat(luck, luck_max_value, luck_scale)
	
	# Crit chance từ luck only
	critical_chance = base_crit_chance + (eff_luck * crit_per_luck)
	# Áp dụng crit chance boost từ special upgrades
	critical_chance += get_special_upgrade_bonus(SpecialUpgradeType.CRIT_CHANCE_BOOST)
	
	# Crit multiplier từ luck
	critical_multiplier = base_crit_multiplier + (eff_luck * crit_mult_per_luck)
	
	if old_crit != critical_chance:
		stat_changed.emit("critical_chance", old_crit, critical_chance)
	if old_crit_mult != critical_multiplier:
		stat_changed.emit("critical_multiplier", old_crit_mult, critical_multiplier)

# === COMBAT CALCULATIONS ===

func calculate_damage_dealt(base_dmg: float = 0.0) -> float:
	"""Tính damage gây ra (có xét crit và damage_multiplier từ abilities)"""
	var final_damage = base_dmg if base_dmg > 0.0 else base_damage
	
	# Áp dụng damage_multiplier từ abilities (như Battle Fury)
	final_damage *= damage_multiplier
	
	# Roll for critical hit
	if randf() < critical_chance:
		final_damage *= critical_multiplier
	
	return final_damage

func calculate_damage_taken(incoming_damage: float) -> float:
	"""Tính damage nhận vào sau khi trừ defense, defense_bonus và áp dụng damage reduction"""
	# Áp dụng cả defense base và bonus từ abilities
	var total_defense = defense + defense_bonus
	var reduced_damage = incoming_damage - total_defense
	reduced_damage = max(1.0, reduced_damage)  # Tối thiểu 1 damage
	# Áp dụng damage reduction % từ special upgrades
	reduced_damage *= (1.0 - damage_reduction)
	return max(1.0, reduced_damage)  # Vẫn tối thiểu 1 damage

# === UTILITY METHODS ===

func get_stat_summary() -> Dictionary:
	"""Trả về dictionary chứa tất cả stats"""
	return {
		"level": current_level,
		"experience": current_experience,
		"exp_to_next": experience_to_next_level,
		"basic_stat_points": basic_stat_points,
		"special_upgrade_points": special_upgrade_points,
		
		"strength": strength,
		"vitality": vitality,
		"dexterity": dexterity,
		"movement_speed": movement_speed,
		"luck": luck,
		
		"max_health": max_health,
		"base_damage": base_damage,
		"defense": defense,
		"move_speed": move_speed,
		"attack_speed": attack_speed_multiplier,
		"crit_chance": critical_chance,
		"crit_multiplier": critical_multiplier,
		"cooldown_reduction": cooldown_reduction,
		"damage_reduction": damage_reduction,
		"hp_regen_per_second": hp_regen_per_second,
	}

func reset_to_level_one() -> void:
	"""Reset về level 1 (cho new game+)"""
	current_level = 1
	current_experience = 0
	strength = 0
	vitality = 0
	dexterity = 0
	movement_speed = 0
	luck = 0
	basic_stat_points = 0
	special_upgrade_points = 0
	active_special_upgrades.clear()
	_recalculate_all_stats()
	_update_exp_requirement()

func save_to_dict() -> Dictionary:
	"""Lưu stats ra dictionary để save game"""
	return {
		"level": current_level,
		"exp": current_experience,
		"basic_points": basic_stat_points,
		"special_points": special_upgrade_points,
		"str": strength,
		"vit": vitality,
		"dex": dexterity,
		"mov": movement_speed,
		"lck": luck,
		"upgrades": active_special_upgrades.duplicate(),
	}

func load_from_dict(data: Dictionary) -> void:
	"""Load stats từ dictionary (save game)"""
	current_level = data.get("level", 1)
	current_experience = data.get("exp", 0)
	basic_stat_points = data.get("basic_points", 0)
	special_upgrade_points = data.get("special_points", 0)
	strength = data.get("str", 0)
	vitality = data.get("vit", 0)
	dexterity = data.get("dex", 0)
	movement_speed = data.get("mov", 0)
	luck = data.get("lck", 0)
	active_special_upgrades = data.get("upgrades", []).duplicate()
	_recalculate_all_stats()
	_update_exp_requirement()
