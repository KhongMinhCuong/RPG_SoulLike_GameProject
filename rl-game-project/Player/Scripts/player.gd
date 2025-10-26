extends "res://Player/Scripts/player_api.gd"
class_name Player

## Concrete Player implementation - kết nối State Machine và Controller
## Xử lý lifecycle, touch controls, và delegates input/physics cho State Machine

@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var controller: PlayerController = $Controller
@onready var stats_ui: CanvasLayer = $UI/StatsUI  # Stats UI để hiển thị level/stats

func _ready() -> void:
	# === INITIALIZE STATS SYSTEM ===
	# Tạo base stats nếu chưa có
	if not base_stats:
		base_stats = PlayerStats.new()
		print("[Player] Created new PlayerStats")
	
	# Initialize runtime stats
	if runtime_stats:
		runtime_stats.initialize(base_stats)
		# Connect runtime stats signals
		runtime_stats.health_changed.connect(_on_runtime_health_changed)
		runtime_stats.health_depleted.connect(_on_death)
	else:
		push_error("[Player] RuntimeStats node not found! Add it to scene.")
	
	# Setup animation và UI
	if animated_sprite:
		animated_sprite.play(&"idle")
	
	if health_bar:
		var max_hp = get_max_health()
		health_bar.init_health(max_hp)
		health_bar.health = runtime_stats.current_health if runtime_stats else max_hp
	
	# Setup StatsUI
	if stats_ui and base_stats:
		stats_ui.setup(base_stats)
		stats_ui.stats_ui_closed.connect(_on_stats_ui_closed)
		stats_ui.hide()  # Ẩn mặc định, nhấn Tab để mở
	
	# Setup touch controls nếu dùng LocalController
	if controller is LocalController:
		if touch_controls:
			controller.joystick_left = joystick_left
			controller.joystick_right = joystick_right
			# Connect touch button signals
			touch_controls.attack_pressed.connect(_on_attack_pressed)
			touch_controls.dash_pressed.connect(_on_dash_pressed)
			touch_controls.parry_pressed.connect(_on_parry_pressed)
			touch_controls.sp_atk_pressed.connect(_on_sp_atk_pressed)
		else:
			push_warning("TouchControls not assigned to Player.")
	
	# Connect signals để state machine xử lý chuyển state
	hit_taken.connect(_on_hit_taken)

func _physics_process(delta: float) -> void:
	if current_action == Action.DEAD:
		return
	
	# Update runtime stats (cooldowns)
	if runtime_stats:
		runtime_stats.update(delta)
	
	# Toggle StatsUI khi nhấn Tab
	if Input.is_action_just_pressed("ui_focus_next"):  # Tab key
		_toggle_stats_ui()
	
	# Update combo timer (countdown cho combo window timeout)
	_update_combo_timer(delta)
	
	# Delegate tất cả input và physics cho state machine
	if state_machine and controller:
		state_machine.handle_input(controller)
		state_machine.physics_update(delta)
		
		# Clear touch flags sau mỗi frame để tránh input buffering
		if controller is LocalController:
			controller.clear_touch_flags()
	
	# Update sprite orientation (rotation bởi joystick phải)
	_update_sprite_orientation()
	
	# Apply physics
	move_and_slide()

# === SPRITE ORIENTATION ===

func _update_sprite_orientation() -> void:
	"""Rotate sprite theo joystick phải (nếu có)"""
	if controller and controller.is_right_stick_pressed():
		rotation = controller.get_right_stick().angle()

# === COMBO TIMER ===

func _update_combo_timer(delta: float) -> void:
	"""Update combo window timer - tự động reset combo khi hết thời gian"""
	if _combo_window_timer <= 0.0:
		return

	_combo_window_timer -= delta
	if _combo_window_timer <= 0.0:
		_reset_combo()

# === ANIMATION HELPERS ===

func _get_animation_length(anim_name: StringName) -> float:
	"""Tính độ dài animation theo frame count và animation speed"""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return 0.0

	var frames := animated_sprite.sprite_frames
	var frame_count := frames.get_frame_count(anim_name)
	var anim_speed := frames.get_animation_speed(anim_name)
	if frame_count <= 0 or anim_speed <= 0.0:
		return 0.0

	return frame_count / anim_speed

func _play_animation_if_needed(anim_name: StringName) -> void:
	"""Deprecated: Dùng play_animation() từ PlayerAPI thay thế"""
	play_animation(anim_name)

# === SIGNAL HANDLERS ===

func _on_runtime_health_changed(current: float, max_hp: float) -> void:
	"""Update UI khi health thay đổi (từ RuntimeStats)"""
	if health_bar:
		# Ensure the progress bar max matches runtime max before assigning current value
		health_bar.max_value = max_hp
		# If DamageBar child is exposed on the health_bar script, update its max as well
		if health_bar.has_node("DamageBar"):
			health_bar.get_node("DamageBar").max_value = max_hp
		# Now assign current health (the setter will clamp against max_value)
		health_bar.health = current
	# Emit health_changed signal để giữ tương thích với code cũ
	health_changed.emit(current, max_hp)

func _on_death() -> void:
	"""Xử lý khi hết máu (từ RuntimeStats.health_depleted)"""
	if state_machine:
		state_machine.change_state("DeadState")

func _on_hit_taken(_amount: float) -> void:
	"""Chuyển sang HitstunState khi bị hit"""
	# Chỉ vào hitstun nếu không đang ở HITSTUN hoặc DEAD
	if current_action != Action.DEAD and current_action != Action.HITSTUN and state_machine:
		_interrupt_current_action()
		state_machine.change_state("HitstunState")

func _toggle_stats_ui() -> void:
	"""Toggle hiển thị/ẩn StatsUI khi nhấn Tab"""
	if stats_ui:
		if stats_ui.visible:
			stats_ui.hide()
			# Enable touch controls khi đóng stats
			if touch_controls:
				touch_controls.visible = true
			print("[Player] Stats UI hidden")
		else:
			stats_ui.show()
			# Disable touch controls khi mở stats
			if touch_controls:
				touch_controls.visible = false
			print("[Player] Stats UI shown")

func _on_stats_ui_closed() -> void:
	"""Xử lý khi StatsUI đóng bằng Close button"""
	if touch_controls:
		touch_controls.visible = true
	print("[Player] Stats UI closed via button")

# === TOUCH CONTROL CALLBACKS ===

func _on_attack_pressed() -> void:
	"""Touch button attack - set flag trong LocalController"""
	if controller and controller is LocalController:
		controller._attack_pressed = true

func _on_dash_pressed() -> void:
	"""Touch button dash - set flag trong LocalController"""
	if controller and controller is LocalController:
		controller._dash_pressed = true

func _on_parry_pressed() -> void:
	"""Touch button parry - set flag trong LocalController"""
	if controller and controller is LocalController:
		controller._parry_pressed = true

func _on_sp_atk_pressed() -> void:
	"""Touch button special - set flag trong LocalController"""
	if controller and controller is LocalController:
		controller._special_pressed = true
