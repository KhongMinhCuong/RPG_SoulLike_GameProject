## StatsUI - UI để hiển thị stats và level up
extends CanvasLayer

# === SIGNALS ===
signal stats_ui_closed

# === REFERENCES ===
@onready var level_label: Label = $VBox/LevelPanel/VBox/LevelLabel
@onready var exp_bar: ProgressBar = $VBox/LevelPanel/VBox/ExpBar
@onready var exp_label: Label = $VBox/LevelPanel/VBox/ExpLabel

# Dual points (fallback to old single label if not exists)
@onready var basic_points_label: Label = get_node_or_null("VBox/MainContent/StatsPanel/VBox/BasicPointsLabel")
@onready var special_points_label: Label = get_node_or_null("VBox/MainContent/StatsPanel/VBox/SpecialPointsLabel")
@onready var stat_points_label: Label = $VBox/MainContent/StatsPanel/VBox/PointsLabel  # Fallback

@onready var str_label: Label = $VBox/MainContent/StatsPanel/VBox/Stats/StrRow/ValueLabel
@onready var str_button: Button = $VBox/MainContent/StatsPanel/VBox/Stats/StrRow/PlusButton

@onready var vit_label: Label = $VBox/MainContent/StatsPanel/VBox/Stats/VitRow/ValueLabel
@onready var vit_button: Button = $VBox/MainContent/StatsPanel/VBox/Stats/VitRow/PlusButton

# Dex uses AgiRow for backward compatibility
@onready var dex_label: Label = $VBox/MainContent/StatsPanel/VBox/Stats/AgiRow/ValueLabel
@onready var dex_button: Button = $VBox/MainContent/StatsPanel/VBox/Stats/AgiRow/PlusButton
@onready var agi_name_label: Label = $VBox/MainContent/StatsPanel/VBox/Stats/AgiRow/NameLabel

# Movement speed (optional new row)
@onready var mov_label: Label = get_node_or_null("VBox/MainContent/StatsPanel/VBox/Stats/MovRow/ValueLabel")
@onready var mov_button: Button = get_node_or_null("VBox/MainContent/StatsPanel/VBox/Stats/MovRow/PlusButton")

@onready var lck_label: Label = $VBox/MainContent/StatsPanel/VBox/Stats/LckRow/ValueLabel
@onready var lck_button: Button = $VBox/MainContent/StatsPanel/VBox/Stats/LckRow/PlusButton

@onready var calculated_stats_label: Label = $VBox/MainContent/CalculatedPanel/VBox/StatsLabel

# Special Upgrade Selection Dialog (modal popup)
@onready var special_upgrade_dialog: AcceptDialog = get_node_or_null("SpecialUpgradeDialog")
var special_upgrade_buttons: Array[Button] = []
var current_special_options: Array = []

@onready var close_button: Button = $VBox/CloseButton

var player_stats: PlayerStats

func _ready() -> void:
	# Change AGI label to DEX for backward compatibility
	if agi_name_label:
		agi_name_label.text = "DEX:"
	
	# Create MovRow if not exists
	if not mov_button or not mov_label:
		_create_movement_speed_row()
	
	# Create special upgrade dialog if not exists
	if not special_upgrade_dialog:
		_create_special_upgrade_dialog()
	
	# Connect buttons
	if str_button:
		str_button.pressed.connect(_on_str_button_pressed)
	if vit_button:
		vit_button.pressed.connect(_on_vit_button_pressed)
	if dex_button:
		dex_button.pressed.connect(_on_dex_button_pressed)
	if mov_button:
		mov_button.pressed.connect(_on_mov_button_pressed)
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
	_update_special_upgrade_display()

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
	var has_basic_points = player_stats.can_spend_basic_point()
	var has_special_points = player_stats.can_spend_special_point()
	
	# Dual point system labels (use new labels if available, fallback to old)
	if basic_points_label and special_points_label:
		basic_points_label.text = "Basic: %d" % player_stats.basic_stat_points
		special_points_label.text = "Special: %d" % player_stats.special_upgrade_points
	elif stat_points_label:
		# Fallback to old single label
		stat_points_label.text = "Points: %d (B:%d S:%d)" % [
			player_stats.basic_stat_points + player_stats.special_upgrade_points,
			player_stats.basic_stat_points,
			player_stats.special_upgrade_points
		]
	
	# Strength - hiển thị cả điểm gốc và giá trị hiệu quả
	if str_label:
		var eff_str = player_stats.effective_stat(player_stats.strength, player_stats.strength_max_value, player_stats.strength_scale)
		str_label.text = "%d (%.1f)" % [player_stats.strength, eff_str]
	if str_button:
		str_button.disabled = not has_basic_points
	
	# Vitality
	if vit_label:
		var eff_vit = player_stats.effective_stat(player_stats.vitality, player_stats.vitality_max_value, player_stats.vitality_scale)
		vit_label.text = "%d (%.1f)" % [player_stats.vitality, eff_vit]
	if vit_button:
		vit_button.disabled = not has_basic_points
	
	# Dexterity - using old AgiRow
	if dex_label:
		var eff_dex = player_stats.effective_stat(player_stats.dexterity, player_stats.dexterity_max_value, player_stats.dexterity_scale)
		dex_label.text = "%d (%.1f)" % [player_stats.dexterity, eff_dex]
	if dex_button:
		dex_button.disabled = not has_basic_points
	
	# Movement Speed - optional new row
	if mov_label:
		var eff_mov = player_stats.effective_stat(player_stats.movement_speed, player_stats.movement_speed_max_value, player_stats.movement_speed_scale)
		mov_label.text = "%d (%.1f)" % [player_stats.movement_speed, eff_mov]
	if mov_button:
		mov_button.disabled = not has_basic_points
	
	# Luck
	if lck_label:
		var eff_lck = player_stats.effective_stat(player_stats.luck, player_stats.luck_max_value, player_stats.luck_scale)
		lck_label.text = "%d (%.1f)" % [player_stats.luck, eff_lck]
	if lck_button:
		lck_button.disabled = not has_basic_points

func _update_calculated_stats_display() -> void:
	"""Update calculated stats - format ngắn gọn cho màn hình nhỏ"""
	if not calculated_stats_label:
		return
	
	var text = ""
	text += "HP: %.0f" % player_stats.max_health
	if player_stats.hp_regen_per_second > 0:
		text += " (+%.1f/s)" % player_stats.hp_regen_per_second
	text += "\n"
	text += "DMG: %.0f\n" % player_stats.base_damage
	text += "DEF: %.0f" % player_stats.defense
	if player_stats.damage_reduction > 0:
		text += " (-%.0f%% DMG)" % (player_stats.damage_reduction * 100)
	text += "\n"
	text += "SPD: %.0f\n" % player_stats.move_speed
	text += "ATK SPD: %.0f%%\n" % (player_stats.attack_speed_multiplier * 100)
	if player_stats.cooldown_reduction > 0:
		text += "CD: -%.0f%%\n" % (player_stats.cooldown_reduction * 100)
	text += "CRIT: %.1f%%\n" % (player_stats.critical_chance * 100)
	text += "DROP: +%.0f%%" % ((player_stats.drop_rate_multiplier - 1.0) * 100)
	
	calculated_stats_label.text = text

# === BUTTON HANDLERS ===

func _on_str_button_pressed() -> void:
	if player_stats and player_stats.increase_stat("strength"):
		update_display()

func _on_vit_button_pressed() -> void:
	if player_stats and player_stats.increase_stat("vitality"):
		update_display()

func _on_dex_button_pressed() -> void:
	if player_stats and player_stats.increase_stat("dexterity"):
		update_display()

func _on_mov_button_pressed() -> void:
	if player_stats and player_stats.increase_stat("movement_speed"):
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
	# Generate new special upgrade options when leveling up
	if player_stats and player_stats.special_upgrade_points > 0:
		_generate_special_upgrade_options()

# === SPECIAL UPGRADE SYSTEM ===

func _create_movement_speed_row() -> void:
	"""Tạo row cho Movement Speed nếu chưa có trong scene"""
	var stats_container = get_node_or_null("VBox/MainContent/StatsPanel/VBox/Stats")
	if not stats_container:
		return
	
	# Tạo MovRow
	var mov_row = HBoxContainer.new()
	mov_row.name = "MovRow"
	stats_container.add_child(mov_row)
	# Đặt giữa DexRow và LckRow
	var lck_row = stats_container.get_node_or_null("LckRow")
	if lck_row:
		stats_container.move_child(mov_row, lck_row.get_index())
	
	# Name Label
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.custom_minimum_size = Vector2(60, 0)
	name_label.text = "MOV:"
	name_label.add_theme_font_size_override("font_size", 10)
	mov_row.add_child(name_label)
	
	# Value Label
	var value_label = Label.new()
	value_label.name = "ValueLabel"
	value_label.custom_minimum_size = Vector2(30, 0)
	value_label.text = "10"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 10)
	mov_row.add_child(value_label)
	mov_label = value_label
	
	# Plus Button
	var plus_button = Button.new()
	plus_button.name = "PlusButton"
	plus_button.custom_minimum_size = Vector2(24, 24)
	plus_button.text = "+"
	plus_button.add_theme_font_size_override("font_size", 10)
	plus_button.pressed.connect(_on_mov_button_pressed)
	mov_row.add_child(plus_button)
	mov_button = plus_button

func _create_special_upgrade_dialog() -> void:
	"""Tầo dialog modal cho special upgrade"""
	special_upgrade_dialog = AcceptDialog.new()
	special_upgrade_dialog.name = "SpecialUpgradeDialog"
	special_upgrade_dialog.title = "SPECIAL UPGRADE - Chọn 1 nâng cấp:"
	special_upgrade_dialog.min_size = Vector2(480, 200)
	special_upgrade_dialog.dialog_close_on_escape = false  # Không cho đóng bằng ESC
	special_upgrade_dialog.dialog_hide_on_ok = false  # Xử lý thủ công
	special_upgrade_dialog.get_ok_button().hide()  # Ẩn nút OK mặc định
	add_child(special_upgrade_dialog)
	
	# Container chính
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	special_upgrade_dialog.add_child(vbox)
	
	# Description label
	var desc_label = Label.new()
	desc_label.text = "Chọn một nâng cấp đặc biệt. Bạn không thể thay đổi sau khi chọn!"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	# Grid container cho 4 buttons (2x2)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(grid)
	
	# Tạo 4 button cho special upgrades
	special_upgrade_buttons.clear()
	for i in range(4):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(210, 70)
		btn.text = "Option %d" % (i + 1)
		btn.add_theme_font_size_override("font_size", 9)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var idx = i  # Capture for closure
		btn.pressed.connect(func(): _on_special_upgrade_selected(idx))
		grid.add_child(btn)
		special_upgrade_buttons.append(btn)

func _update_special_upgrade_display() -> void:
	"""Cập nhật hiển thị special upgrade dialog"""
	if not special_upgrade_dialog:
		return
	
	if player_stats.special_upgrade_points > 0:
		# Nếu chưa có options, generate mới
		if current_special_options.is_empty():
			_generate_special_upgrade_options()
		
		# Hiện dialog modal giữa màn hình
		special_upgrade_dialog.popup_centered()
		
		# Disable base stat buttons khi đang chọn special upgrade
		_set_base_stat_buttons_enabled(false)
	else:
		special_upgrade_dialog.hide()
		current_special_options.clear()
		# Enable lại base stat buttons
		_set_base_stat_buttons_enabled(true)

func _set_base_stat_buttons_enabled(enabled: bool) -> void:
	"""Bật/tắt các nút tăng base stats"""
	if str_button:
		str_button.disabled = not (enabled and player_stats.can_spend_basic_point())
	if vit_button:
		vit_button.disabled = not (enabled and player_stats.can_spend_basic_point())
	if dex_button:
		dex_button.disabled = not (enabled and player_stats.can_spend_basic_point())
	if mov_button:
		mov_button.disabled = not (enabled and player_stats.can_spend_basic_point())
	if lck_button:
		lck_button.disabled = not (enabled and player_stats.can_spend_basic_point())

func _generate_special_upgrade_options() -> void:
	"""Random 4 special upgrade options cho người chơi chọn"""
	if not player_stats:
		return
	
	# Danh sách tất cả các upgrade có thể
	var all_upgrades = [
		{"type": PlayerStats.SpecialUpgradeType.DAMAGE_BOOST, "name": "+5% Damage", "desc": "Tăng sát thương"},
		{"type": PlayerStats.SpecialUpgradeType.HP_REGEN, "name": "+10% HP Regen", "desc": "Hồi máu mỗi giây"},
		{"type": PlayerStats.SpecialUpgradeType.CRIT_CHANCE_BOOST, "name": "+0.5% Crit", "desc": "Tăng chí mạng"},
		{"type": PlayerStats.SpecialUpgradeType.DAMAGE_REDUCTION, "name": "-3% Damage Taken", "desc": "Giảm sát thương nhận"},
		{"type": PlayerStats.SpecialUpgradeType.COOLDOWN_BOOST, "name": "-5% Cooldown", "desc": "Giảm thời gian hồi kỹ năng"},
		{"type": PlayerStats.SpecialUpgradeType.MOVE_SPEED_BOOST, "name": "+5% Move Speed", "desc": "Tăng tốc độ di chuyển"},
		{"type": PlayerStats.SpecialUpgradeType.ATTACK_SPEED_BOOST, "name": "+5% Attack Speed", "desc": "Tăng tốc độ tấn công"},
	]
	
	# Shuffle và chọn 4 options
	all_upgrades.shuffle()
	current_special_options = all_upgrades.slice(0, 4)
	
	# Cập nhật text cho các button
	for i in range(min(4, special_upgrade_buttons.size())):
		if i < current_special_options.size():
			var option = current_special_options[i]
			special_upgrade_buttons[i].text = option["name"] + "\n" + option["desc"]
			special_upgrade_buttons[i].disabled = false
			special_upgrade_buttons[i].visible = true
		else:
			special_upgrade_buttons[i].visible = false

func _on_special_upgrade_selected(index: int) -> void:
	"""Xử lý khi người chơi chọn special upgrade"""
	if not player_stats or index >= current_special_options.size():
		return
	
	var selected_option = current_special_options[index]
	var upgrade_type = selected_option["type"]
	
	# Apply upgrade
	if player_stats.apply_special_upgrade(upgrade_type):
		print("[StatsUI] Applied special upgrade: ", selected_option["name"])
		
		# Clear options và ẩn dialog
		current_special_options.clear()
		special_upgrade_dialog.hide()
		
		# Enable lại base stat buttons
		_set_base_stat_buttons_enabled(true)
		
		# Cập nhật UI
		update_display()
	else:
		push_warning("[StatsUI] Failed to apply special upgrade")
