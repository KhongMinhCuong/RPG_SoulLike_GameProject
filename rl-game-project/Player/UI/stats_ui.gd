## StatsUI - UI để hiển thị stats và level up
extends CanvasLayer

# === SIGNALS ===
signal stats_ui_closed

# === REFERENCES ===
@onready var level_label: Label = $VBox/LevelPanel/VBox/LevelLabel
@onready var exp_bar: ProgressBar = $VBox/LevelPanel/VBox/ExpBar
@onready var exp_label: Label = $VBox/LevelPanel/VBox/ExpLabel

@onready var stat_points_label: Label = $VBox/MainContent/StatsPanel/VBox/PointsLabel

@onready var str_label: Label = $VBox/MainContent/StatsPanel/VBox/Stats/StrRow/ValueLabel
@onready var str_button: Button = $VBox/MainContent/StatsPanel/VBox/Stats/StrRow/PlusButton

@onready var vit_label: Label = $VBox/MainContent/StatsPanel/VBox/Stats/VitRow/ValueLabel
@onready var vit_button: Button = $VBox/MainContent/StatsPanel/VBox/Stats/VitRow/PlusButton

@onready var agi_label: Label = $VBox/MainContent/StatsPanel/VBox/Stats/AgiRow/ValueLabel
@onready var agi_button: Button = $VBox/MainContent/StatsPanel/VBox/Stats/AgiRow/PlusButton

@onready var lck_label: Label = $VBox/MainContent/StatsPanel/VBox/Stats/LckRow/ValueLabel
@onready var lck_button: Button = $VBox/MainContent/StatsPanel/VBox/Stats/LckRow/PlusButton

@onready var calculated_stats_label: Label = $VBox/MainContent/CalculatedPanel/VBox/StatsLabel
@onready var close_button: Button = $VBox/CloseButton

var player_stats: PlayerStats

func _ready() -> void:
	# Connect buttons
	if str_button:
		str_button.pressed.connect(_on_str_button_pressed)
	if vit_button:
		vit_button.pressed.connect(_on_vit_button_pressed)
	if agi_button:
		agi_button.pressed.connect(_on_agi_button_pressed)
	if lck_button:
		lck_button.pressed.connect(_on_lck_button_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

func setup(stats: PlayerStats) -> void:
	"""Setup UI với PlayerStats instance"""
	player_stats = stats
	
	if player_stats:
		# Connect signals
		player_stats.level_up.connect(_on_level_up)
		player_stats.experience_gained.connect(_on_exp_gained)
		player_stats.stat_changed.connect(_on_stat_changed)
	
	update_display()

func update_display() -> void:
	"""Update toàn bộ UI"""
	if not player_stats:
		return
	
	_update_level_display()
	_update_stats_display()
	_update_calculated_stats_display()

func _update_level_display() -> void:
	"""Update level và exp bar"""
	if level_label:
		level_label.text = "Level: %d" % player_stats.current_level
	
	if exp_bar:
		exp_bar.max_value = player_stats.experience_to_next_level
		exp_bar.value = player_stats.current_experience
	
	if exp_label:
		exp_label.text = "%d / %d EXP" % [
			player_stats.current_experience,
			player_stats.experience_to_next_level
		]

func _update_stats_display() -> void:
	"""Update base stats và buttons"""
	var has_points = player_stats.can_spend_stat_point()
	
	# Stat points - text ngắn cho màn hình nhỏ
	if stat_points_label:
		stat_points_label.text = "Points: %d" % player_stats.unspent_stat_points
	
	# Strength
	if str_label:
		str_label.text = str(player_stats.strength)
	if str_button:
		str_button.disabled = not has_points
	
	# Vitality
	if vit_label:
		vit_label.text = str(player_stats.vitality)
	if vit_button:
		vit_button.disabled = not has_points
	
	# Agility
	if agi_label:
		agi_label.text = str(player_stats.agility)
	if agi_button:
		agi_button.disabled = not has_points
	
	# Luck
	if lck_label:
		lck_label.text = str(player_stats.luck)
	if lck_button:
		lck_button.disabled = not has_points

func _update_calculated_stats_display() -> void:
	"""Update calculated stats - format ngắn gọn cho màn hình nhỏ"""
	if not calculated_stats_label:
		return
	
	var text = ""
	text += "HP: %.0f\n" % player_stats.max_health
	text += "DMG: %.0f\n" % player_stats.base_damage
	text += "DEF: %.0f\n" % player_stats.defense
	text += "SPD: %.0f\n" % player_stats.move_speed
	text += "ATK%%: %.0f%%\n" % (player_stats.attack_speed_multiplier * 100)
	text += "CRIT: %.0f%%\n" % (player_stats.critical_chance * 100)
	text += "DROP: +%.0f%%" % ((player_stats.drop_rate_multiplier - 1.0) * 100)
	
	calculated_stats_label.text = text

# === BUTTON HANDLERS ===

func _on_str_button_pressed() -> void:
	if player_stats and player_stats.increase_stat("strength"):
		update_display()

func _on_vit_button_pressed() -> void:
	if player_stats and player_stats.increase_stat("vitality"):
		update_display()

func _on_agi_button_pressed() -> void:
	if player_stats and player_stats.increase_stat("agility"):
		update_display()

func _on_lck_button_pressed() -> void:
	if player_stats and player_stats.increase_stat("luck"):
		update_display()

func _on_close_button_pressed() -> void:
	"""Đóng stats UI khi nhấn Close button"""
	hide()
	stats_ui_closed.emit()  # Notify player to re-enable touch controls

# === SIGNAL HANDLERS ===

func _on_level_up(new_level: int) -> void:
	print("[StatsUI] Level up to ", new_level, "!")
	update_display()
	
	# Show level up effect
	_show_level_up_effect()

func _on_exp_gained(_amount: int, _total: int) -> void:
	_update_level_display()

func _on_stat_changed(_stat_name: String, _old: float, _new: float) -> void:
	update_display()

func _show_level_up_effect() -> void:
	"""Hiển thị effect khi level up (có thể customize)"""
	# TODO: Add particle effect, sound, animation
	pass
