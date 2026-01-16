extends PlayerAPI
class_name Player

## Concrete Player implementation - kết nối State Machine và Controller
## Xử lý lifecycle, touch controls, và delegates input/physics cho State Machine

@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var controller: PlayerController = $Controller
@onready var stats_ui: CanvasLayer = $UI/StatsUI  # Stats UI để hiển thị level/stats

# AbilityManager - auto-created if not exists
var ability_manager: Node = null

# Loaded character data reference
var character_data: Resource = null

@export var direction: int

func _ready() -> void:
	# === INITIALIZE STATS SYSTEM ===
	# Tạo base stats nếu chưa có
	if not base_stats:
		base_stats = PlayerStats.new()
		print("[Player] Created new PlayerStats")
	
	# Load character data từ GameManager (nếu đã chọn nhân vật)
	# NOTE: GameManager phải được add vào Autoload trước (Project Settings → Autoload)
	if has_node("/root/GameManager"):
		var game_manager = get_node("/root/GameManager")
		if game_manager.has_method("has_selected_character") and game_manager.has_selected_character():
			character_data = game_manager.get_selected_character()
			character_data.apply_to_stats(base_stats)
			print("[Player] Loaded character: ", character_data.character_name)
			
			# Load ranged character flag
			if "is_ranged_character" in character_data:
				is_ranged_character = character_data.is_ranged_character
				print("[Player] Is ranged: ", is_ranged_character)
			
			# Apply sprite frames nếu có
			if character_data.sprite_frames and animated_sprite:
				animated_sprite.sprite_frames = character_data.sprite_frames
			
			# Setup AbilityManager sau khi load character data
			_setup_ability_manager()
			
			# Setup ProjectileSpawner cho ranged characters
			if is_ranged_character:
				_setup_projectile_spawner()
		else:
			# Fallback: Grant starter points nếu không có character data (debug mode)
			print("[Player] No character selected - using debug mode")
			base_stats.add_basic_stat_points(100)
			base_stats.add_special_upgrade_points(3)
	else:
		# GameManager chưa được add vào Autoload - dùng debug mode
		print("[Player] GameManager not found - using debug mode")
		print("  → Add GameManager to Autoload: Project → Project Settings → Autoload")
		base_stats.add_basic_stat_points(100)
		base_stats.add_special_upgrade_points(3)
	
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
	
	# Update direction only when moving, preserve last direction when idle
	var move_dir = sign(controller.get_move_direction().x) if controller else 0
	
	# Always track input direction
	if move_dir != 0:
		pre_dir = move_dir
	
	# Only update facing direction if not attacking
	var is_attacking = current_action in [Action.ATTACK, Action.AIR_ATTACK, Action.SPECIAL]
	if move_dir != 0 and not is_attacking:
		direction = pre_dir
	elif direction == 0:  # Initialize first time
		direction = 1
	
	# Flip sprite according to direction
	if animated_sprite:
		animated_sprite.flip_h = (direction < 0)

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

# === ABILITY MANAGER SETUP ===

func _setup_ability_manager() -> void:
	"""Tạo và setup AbilityManager để load abilities từ CharacterData"""
	# Check if AbilityManager exists as child
	ability_manager = get_node_or_null("AbilityManager")
	
	if not ability_manager:
		# Create AbilityManager dynamically
		var AbilityManagerScript = load("res://Player/Scripts/Abilities/ability_manager.gd")
		if AbilityManagerScript:
			ability_manager = Node.new()
			ability_manager.name = "AbilityManager"
			ability_manager.set_script(AbilityManagerScript)
			add_child(ability_manager)
			print("[Player] AbilityManager created dynamically")
		else:
			push_error("[Player] Could not load AbilityManager script!")
			return
	
	print("[Player] AbilityManager ready: ", ability_manager.name)

func get_character_data() -> Resource:
	"""Return loaded character data for AbilityManager"""
	return character_data

# === PROJECTILE SPAWNER SETUP ===

func _setup_projectile_spawner() -> void:
	"""Load projectile scene từ CharacterData vào ProjectileSpawner"""
	var spawner = get_node_or_null("ProjectileSpawner")
	if not spawner:
		push_warning("[Player] ProjectileSpawner not found! Add it to scene for ranged characters.")
		return
	
	# Load default projectile scene từ CharacterData
	if character_data and "projectile_scene_path" in character_data:
		var path = character_data.projectile_scene_path
		if path != "" and spawner.has_method("load_projectile_scene"):
			spawner.load_projectile_scene(path)
			print("[Player] Projectile scene loaded: ", path)
