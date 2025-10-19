class_name PlayerAPI
extends CharacterBody2D

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

@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0
@export var dash_speed: float = 400.0
@export var dash_duration: float = 0.2
@export var max_health: float = 100.0
@export var combo_window: float = 0.45

@export var joystick_left: VirtualJoystick
@export var joystick_right: VirtualJoystick
@export var touch_controls: TouchControls

@onready var animated_sprite: AnimatedSprite2D = $Sprite2D
@onready var health_bar = $UI/HealthBar

enum Action { NONE, ATTACK, AIR_ATTACK, DASH, PARRY, SPECIAL, HITSTUN, DEAD }

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

const GROUND_COMBO: Array[Dictionary] = [
	{"anim": &"1_atk", "end_anim": &"1_atk_end", "buffer_ratio": 0.6},
	{"anim": &"2_atk", "end_anim": &"2_atk_end", "buffer_ratio": 0.6},
	{"anim": &"3_atk", "end_anim": &"", "buffer_ratio": 0.65},
]

const AIR_ATTACK: Dictionary = {"anim": &"air_atk"}

var move_vector := Vector2.ZERO
var current_health: float = 0.0
var current_action: int = Action.NONE
var dash_direction := Vector2.ZERO

var _action_token: int = 0
var _combo_step: int = -1
var _combo_window_timer: float = 0.0
var _combo_buffered: bool = false
var _combo_accepting_buffer: bool = false
var _air_attack_used: bool = false
@warning_ignore("unused_private_class_variable")
var _last_move_direction: float = 1.0

func request_attack() -> void:
	if current_action in [Action.SPECIAL, Action.PARRY, Action.DASH, Action.HITSTUN, Action.DEAD]:
		return

	if not is_on_floor():
		if _air_attack_used or current_action == Action.AIR_ATTACK:
			return
		_begin_air_attack()
		return

	if current_action == Action.ATTACK:
		if _combo_accepting_buffer:
			_combo_buffered = true
		return

	if not _can_perform_basic_action():
		return

	if _combo_window_timer <= 0.0:
		_combo_step = 0
	else:
		_combo_step = clamp(_combo_step + 1, 0, GROUND_COMBO.size() - 1)

	_combo_window_timer = 0.0
	_begin_ground_attack(_combo_step)

func request_dash(direction_override: float = 0.0) -> void:
	if current_action in [Action.DASH, Action.SPECIAL, Action.PARRY, Action.HITSTUN, Action.DEAD]:
		return

	if _can_cancel_with_dash():
		_interrupt_current_action()
		_reset_combo()

	var direction := direction_override
	if direction == 0.0:
		var input_direction := Input.get_axis("ui_left", "ui_right")
		if input_direction != 0.0:
			direction = input_direction
		elif dash_direction.x != 0.0:
			direction = dash_direction.x
		else:
			direction = -1.0 if animated_sprite.flip_h else 1.0

	_start_dash(direction)

func request_parry() -> void:
	if current_action in [Action.PARRY, Action.DASH, Action.SPECIAL, Action.HITSTUN, Action.DEAD]:
		return

	_interrupt_current_action()
	var token := _start_action(Action.PARRY)
	animated_sprite.play(&"defend")
	await animated_sprite.animation_finished
	if token != _action_token:
		return
	_end_action(token)

func request_special() -> void:
	if current_action in [Action.SPECIAL, Action.DASH, Action.PARRY, Action.HITSTUN, Action.DEAD]:
		return

	_interrupt_current_action()
	var token := _start_action(Action.SPECIAL)
	velocity = Vector2.ZERO
	animated_sprite.play(&"sp_atk")
	await animated_sprite.animation_finished
	if token != _action_token:
		return
	_end_action(token)

func take_damage(amount: float) -> void:
	if current_action == Action.DEAD:
		return

	hit_taken.emit(amount)
	current_health = max(current_health - amount, 0.0)
	if health_bar:
		health_bar.health = current_health
	health_changed.emit(current_health, max_health)

	if current_health <= 0.0:
		_die()
		return

	_interrupt_current_action()
	_reset_combo()
	var token := _start_action(Action.HITSTUN)
	animated_sprite.play(&"take_hit")
	await animated_sprite.animation_finished
	if token != _action_token:
		return
	_end_action(token)

func apply_damage(amount: float) -> void:
	take_damage(amount)

func heal(amount: float) -> void:
	if current_action == Action.DEAD:
		return

	current_health = clamp(current_health + amount, 0.0, max_health)
	if health_bar:
		health_bar.health = current_health
	health_changed.emit(current_health, max_health)

func force_cancel_action() -> void:
	_interrupt_current_action()
	_reset_combo()

func is_busy() -> bool:
	return current_action != Action.NONE

func is_action_active(action: StringName) -> bool:
	for candidate in ACTION_LABELS.keys():
		var label := ACTION_LABELS[candidate] as StringName
		if label == action:
			return current_action == candidate
	return false

func _start_action(action: int) -> int:
	_action_token += 1
	current_action = action
	action_started.emit(ACTION_LABELS.get(action, &"unknown") as StringName)
	return _action_token

func _end_action(token: int) -> void:
	if token != _action_token:
		return
	var label: StringName = ACTION_LABELS.get(current_action, &"unknown") as StringName
	current_action = Action.NONE
	action_finished.emit(label)

func _interrupt_current_action() -> void:
	if current_action == Action.NONE:
		return
	var label: StringName = ACTION_LABELS.get(current_action, &"unknown") as StringName
	_action_token += 1
	current_action = Action.NONE
	action_finished.emit(label)
	if animated_sprite:
		animated_sprite.stop()

func _reset_combo() -> void:
	_combo_step = -1
	_combo_window_timer = 0.0
	_combo_buffered = false
	_combo_accepting_buffer = false

func _can_perform_basic_action() -> bool:
	return false

func _can_cancel_with_dash() -> bool:
	return false

func _begin_ground_attack(_step: int) -> void:
	pass

func _begin_air_attack() -> void:
	pass

func _start_dash(_direction: float) -> void:
	pass

func _die() -> void:
	pass

# Touch button callbacks
func _on_attack_pressed() -> void:
	request_attack()

func _on_dash_pressed() -> void:
	request_dash()

func _on_parry_pressed() -> void:
	request_parry()

func _on_sp_atk_pressed() -> void:
	request_special()
