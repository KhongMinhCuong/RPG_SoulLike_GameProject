## Controller đọc input từ keyboard/gamepad local
class_name LocalController
extends PlayerController

@export var move_left: String = "ui_left"
@export var move_right: String = "ui_right"
@export var jump_action: String = "ui_up"
@export var attack_action: String = "player_attack"
@export var dash_action: String = "player_roll"
@export var parry_action: String = "parry"
@export var special_action: String = "special"

@export var joystick_left: VirtualJoystick
@export var joystick_right: VirtualJoystick

# Touch control flags
var _attack_pressed: bool = false
var _dash_pressed: bool = false
var _parry_pressed: bool = false
var _special_pressed: bool = false

func get_move_direction() -> Vector2:
	var x := Input.get_axis(move_left, move_right)
	
	# Nếu có virtual joystick, ưu tiên joystick
	if joystick_left and joystick_left.is_pressed:
		x = joystick_left.output.x
	
	return Vector2(x, 0.0)

func get_jump_input() -> bool:
	return Input.is_action_just_pressed(jump_action)

func get_attack_input() -> bool:
	return Input.is_action_just_pressed(attack_action) or _attack_pressed

func get_dash_input() -> bool:
	return Input.is_action_just_pressed(dash_action) or _dash_pressed

func get_parry_input() -> bool:
	return Input.is_action_just_pressed(parry_action) or _parry_pressed

func get_special_input() -> bool:
	return Input.is_action_just_pressed(special_action) or _special_pressed

func get_right_stick() -> Vector2:
	if joystick_right and joystick_right.is_pressed:
		return joystick_right.output
	return Vector2.ZERO

func is_right_stick_pressed() -> bool:
	return joystick_right != null and joystick_right.is_pressed

## Clear all touch flags at end of frame
func clear_touch_flags() -> void:
	_attack_pressed = false
	_dash_pressed = false
	_parry_pressed = false
	_special_pressed = false
