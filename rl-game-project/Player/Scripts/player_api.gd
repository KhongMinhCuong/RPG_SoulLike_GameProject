## Base class cho Player - cung cấp API và data cho các State
## Không xử lý logic game trực tiếp, chỉ expose methods và properties
extends CharacterBody2D
class_name PlayerAPI

# === SIGNALS ===
signal health_changed(current: float, max_value: float)
@warning_ignore("unused_signal")
signal died
@warning_ignore("unused_signal")
signal action_started(action: StringName)
@warning_ignore("unused_signal")
signal action_finished(action: StringName)
@warning_ignore("unused_signal")
signal combo_step_started(step_index: int)
@warning_ignore("unused_signal")
signal dash_performed(direction: float)
signal hit_taken(amount: float)

# === STATS SYSTEM ===
## PlayerStats resource - quản lý base stats, level, experience
@export var base_stats: PlayerStats

# === EXPORTED PROPERTIES ===
## Physics properties (không còn trong stats)
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0
@export var dash_duration: float = 0.2
@export var combo_window: float = 0.45  # Thời gian buffer combo

## Special attack properties
@export var invincible_during_special: bool = false  # Nhân vật bất tử khi dùng sp_atk

## Ranged Character Flag
@export var is_ranged_character: bool = false  # True = spawn projectile, False = melee hitbox

## Direction tracking
var pre_dir: int = 1  # Previous/pending direction from input

## Parry state
var is_parrying: bool = false  # Currently in parry window

# Touch controls
@export var joystick_left: VirtualJoystick
@export var joystick_right: VirtualJoystick
@export var touch_controls: TouchControls

@onready var animated_sprite: AnimatedSprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_bar = $UI/HealthBar
@onready var runtime_stats: PlayerRuntimeStats = $RuntimeStats
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox

# === ENUMS ===
enum Action { NONE, ATTACK, AIR_ATTACK, DASH, PARRY, SPECIAL, HITSTUN, DEAD }

# Mapping từ Action enum sang StringName để emit signals
const ACTION_LABELS: Dictionary = {
	Action.NONE: &"none",
	Action.ATTACK: &"attack",
	Action.AIR_ATTACK: &"air_attack",
	Action.DASH: &"dash",
	Action.PARRY: &"parry",
	Action.SPECIAL: &"special",
	Action.HITSTUN: &"hitstun",
	Action.DEAD: &"dead",
}

# Combo config - buffer_ratio là % thời gian animation trước khi mở combo window
const GROUND_COMBO: Array[Dictionary] = [
	{"anim": &"1_atk", "end_anim": &"1_atk_end", "buffer_ratio": 0.6},
	{"anim": &"2_atk", "end_anim": &"2_atk_end", "buffer_ratio": 0.6},
	{"anim": &"3_atk", "end_anim": &"", "buffer_ratio": 0.65},  # Không có end_anim
]

const AIR_ATTACK: Dictionary = {"anim": &"air_atk"}

# === PUBLIC VARIABLES ===
var move_vector := Vector2.ZERO  # Deprecated - không dùng nữa
var current_action: int = Action.NONE  # Action hiện tại
var dash_direction := Vector2.ZERO  # Hướng dash gần nhất

# Computed property for hitbox damage
var damage: float:
	get:
		return base_stats.base_damage if base_stats else 10.0

# Flag to prevent damage when attack is interrupted
var _allow_hitbox_activation: bool = false

# === ANIMATION METHODS (callable from AnimationPlayer) ===
func enable_hitbox_shape(shape_index: int) -> void:
	"""Enable specific hitbox shape - callable from AnimationPlayer method tracks"""
	# Only enable if attack is still valid (not interrupted)
	if not _allow_hitbox_activation:
		print("[Player] enable_hitbox_shape blocked: _allow_hitbox_activation = false")
		return
	
	# For ranged characters, spawn projectile instead of enabling hitbox
	if is_ranged_character:
		# Shape 4 = special attack laser (không spawn projectile, dùng hitbox)
		if shape_index == 4:
			print("[Player] Special attack - using hitbox and spawning laser visual")
			_spawn_laser_visual()
			# Enable hitbox như melee
			if hitbox:
				hitbox.enable_shape(shape_index)
		else:
			print("[Player] Ranged character - spawning projectile instead of hitbox")
			_spawn_projectile_from_hitbox(shape_index)
	else:
		# Melee: enable hitbox as normal
		if hitbox:
			hitbox.enable_shape(shape_index)

func _spawn_projectile_from_hitbox(shape_index: int = -1) -> void:
	"""Spawn projectile for ranged character - called from enable_hitbox_shape
	shape_index 3 = air attack (bắn chéo), còn lại = combo attack thường"""
	var spawner = get_node_or_null("ProjectileSpawner")
	if spawner:
		print("[Player] ProjectileSpawner found, spawning...")
		
		# Air attack (shape_index 3) sử dụng góc -45 độ và spawn từ hitbox 3
		if shape_index == 3 and spawner.has_method("spawn_air_attack_arrow"):
			spawner.spawn_air_attack_arrow(shape_index)
		elif spawner.has_method("spawn_combo_arrow"):
			spawner.spawn_combo_arrow()
		elif spawner.has_method("spawn_facing_projectile"):
			spawner.spawn_facing_projectile()
	else:
		push_warning("[Player] ProjectileSpawner not found!")

func _spawn_laser_visual() -> void:
	"""Spawn laser visual effect for archer special attack"""
	# Thử load scene mới trước, fallback về scene cũ
	var laser_scene = load("res://Player/Scenes/Projectiles/archer_laser_effect.tscn")
	if not laser_scene:
		laser_scene = load("res://Player/Scenes/Projectiles/archer_laser_beam.tscn")
	
	if not laser_scene:
		push_warning("[Player] Laser effect scene not found!")
		return
	
	var laser = laser_scene.instantiate()
	
	# Position laser tại center của hitbox shape cho special attack (Hitbox5 - index 4)
	var spawn_pos = global_position + Vector2(0, -27.5)  # Default offset
	
	# Tìm hitbox center cho laser (Hitbox5 cho special attack)
	if hitbox:
		var dir_sign = 1.0 if self.direction >= 0 else -1.0
		var children = hitbox.get_children()
		# Hitbox5 là child thứ 5 (index 4) cho special attack laser
		var laser_hitbox_index = 4  
		if children.size() > laser_hitbox_index and children[laser_hitbox_index] is CollisionShape2D:
			var hitbox_shape: CollisionShape2D = children[laser_hitbox_index]
			var shape_pos = hitbox_shape.position
			# Tính center của laser: global_pos + (hitbox_x * direction_sign, hitbox_y)
			spawn_pos = global_position + Vector2(abs(shape_pos.x) * dir_sign, shape_pos.y)
			print("[Player] Using Hitbox5 position: %s, spawn_pos: %s" % [shape_pos, spawn_pos])
	
	laser.global_position = spawn_pos
	
	# Set direction của laser theo hướng player
	if laser.has_method("set_direction"):
		laser.set_direction(self.direction)
	
	# Add to scene
	get_tree().current_scene.add_child(laser)
	print("[Player] Spawned laser visual effect at hitbox center: %s" % spawn_pos)

func disable_all_hitboxes() -> void:
	"""Disable all hitboxes - callable from AnimationPlayer method tracks"""
	if hitbox:
		hitbox.disable()

func play_sprite_animation(anim_name: StringName) -> void:
	"""Play sprite animation - callable from AnimationPlayer"""
	if animated_sprite:
		animated_sprite.play(anim_name)
		# Apply attack speed multiplier for attack animations
		if runtime_stats and (anim_name.contains("atk") or anim_name.contains("attack")):
			var speed_mult = runtime_stats.get_attack_speed_multiplier()
			# Apply speed to BOTH animation_player and animated_sprite
			if animation_player:
				animation_player.speed_scale = speed_mult
			animated_sprite.speed_scale = speed_mult
		else:
			# Reset speed for non-attack animations
			if animation_player:
				animation_player.speed_scale = 1.0
			animated_sprite.speed_scale = 1.0

# === PRIVATE VARIABLES ===
# Token system để invalidate async paths
var _action_token: int = 0

# Combo system
var _combo_step: int = -1  # Bước combo hiện tại (-1 = chưa combo)
var _combo_window_timer: float = 0.0  # Timer đếm combo window timeout
var _combo_buffered: bool = false  # Đã buffer attack input chưa
var _combo_accepting_buffer: bool = false  # Có đang nhận buffer không (combo window)

# Air attack limiter
var _air_attack_used: bool = false  # Đã dùng air attack chưa (reset khi chạm đất)

@warning_ignore("unused_private_class_variable")
var _last_move_direction: float = 1.0

# === VALIDATION METHODS ===
# Các methods này được states dùng để validate trước khi transition

func can_attack() -> bool:
	"""Kiểm tra có thể bắt đầu ground attack không"""
	if current_action in [Action.SPECIAL, Action.PARRY, Action.DASH, Action.HITSTUN, Action.DEAD]:
		return false
	return true

func can_air_attack() -> bool:
	"""Kiểm tra có thể dùng air attack không (chỉ 1 lần trên không)"""
	return not _air_attack_used and current_action != Action.AIR_ATTACK

func can_dash() -> bool:
	"""Kiểm tra có thể dash không"""
	return current_action not in [Action.DASH, Action.SPECIAL, Action.PARRY, Action.HITSTUN, Action.DEAD]

func can_parry() -> bool:
	"""Kiểm tra có thể parry không"""
	return current_action not in [Action.PARRY, Action.DASH, Action.SPECIAL, Action.HITSTUN, Action.DEAD]

func can_special() -> bool:
	"""Kiểm tra có thể dùng special attack không"""
	return current_action not in [Action.SPECIAL, Action.DASH, Action.PARRY, Action.HITSTUN, Action.DEAD]

# === HELPER METHODS ===

func get_dash_direction(input_direction: float = 0.0) -> float:
	"""Tính hướng dash từ input, fallback về dash_direction hoặc sprite flip"""
	if input_direction != 0.0:
		return input_direction
	elif dash_direction.x != 0.0:
		return dash_direction.x
	else:
		return -1.0 if animated_sprite.flip_h else 1.0

# === HEALTH MANAGEMENT ===
# Delegated to RuntimeStats

func take_damage(amount: float) -> void:
	"""Nhận damage - delegate to runtime_stats"""
	if current_action == Action.DEAD or not runtime_stats:
		return
	
	# PARRY MECHANIC: If parrying, take 0 damage and don't interrupt
	if is_parrying:
		print("[Player] Parried attack! Taking 0 damage.")
		# Don't take any damage - skip runtime_stats.take_damage() completely
		# Don't emit hit_taken (prevents state change to HitstunState)
		return
	
	hit_taken.emit(amount)  # Signal để chuyển sang HitstunState
	var _actual_damage = runtime_stats.take_damage(amount)
	
	# Emit for compatibility
	health_changed.emit(runtime_stats.current_health, get_max_health())

func apply_damage(amount: float) -> void:
	"""Alias cho take_damage"""
	take_damage(amount)

func heal(amount: float) -> void:
	"""Hồi máu - delegate to runtime_stats"""
	if current_action == Action.DEAD or not runtime_stats:
		return
	
	runtime_stats.heal(amount)
	health_changed.emit(runtime_stats.current_health, get_max_health())

func get_max_health() -> float:
	"""Lấy max health từ base stats"""
	return base_stats.max_health if base_stats else 100.0

# === UTILITY METHODS ===

func force_cancel_action() -> void:
	"""Force cancel action hiện tại và reset combo"""
	_interrupt_current_action()
	_reset_combo()

func is_busy() -> bool:
	"""Check xem có đang trong action không"""
	return current_action != Action.NONE

func is_action_active(action: StringName) -> bool:
	"""Check action cụ thể có đang active không"""
	for candidate in ACTION_LABELS.keys():
		var label := ACTION_LABELS[candidate] as StringName
		if label == action:
			return current_action == candidate
	return false

func play_animation(anim_name: StringName, force: bool = false) -> void:
	"""Centralized animation control - tránh duplicate animation plays"""
	if not animated_sprite:
		push_warning("AnimatedSprite2D not found!")
		return
	
	if force or animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)
	
	# Apply attack speed multiplier for attack animations
	# Animation names: 1_atk, 2_atk, 3_atk, air_atk, etc.
	if runtime_stats and (anim_name.contains("atk") or anim_name.contains("attack") or anim_name.contains("slash")):
		var speed_mult = runtime_stats.get_attack_speed_multiplier()
		animated_sprite.speed_scale = speed_mult
	else:
		# Reset speed for non-attack animations
		animated_sprite.speed_scale = 1.0

# === ACTION TOKEN SYSTEM ===
# Token được increment mỗi khi start/interrupt action
# Async paths check token để biết có bị invalidate không

func _start_action(action: int) -> int:
	"""Bắt đầu action mới, increment token và return token hiện tại"""
	_action_token += 1
	current_action = action
	action_started.emit(ACTION_LABELS.get(action, &"unknown") as StringName)
	return _action_token

func _end_action(token: int) -> void:
	"""Kết thúc action nếu token còn valid"""
	if token != _action_token:
		return  # Token mismatch = action đã bị interrupt
	var label: StringName = ACTION_LABELS.get(current_action, &"unknown") as StringName
	current_action = Action.NONE
	action_finished.emit(label)

func _interrupt_current_action() -> void:
	"""Force interrupt action hiện tại, invalidate tất cả async paths"""
	if current_action == Action.NONE:
		return
	var label: StringName = ACTION_LABELS.get(current_action, &"unknown") as StringName
	_action_token += 1  # Invalidate all pending async operations
	current_action = Action.NONE
	action_finished.emit(label)
	if animated_sprite:
		animated_sprite.stop()

# === COMBO SYSTEM ===

func _reset_combo() -> void:
	"""Reset tất cả combo state về mặc định"""
	_combo_step = -1
	_combo_window_timer = 0.0
	_combo_buffered = false
	_combo_accepting_buffer = false
