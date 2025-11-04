## Base class cho tất cả controller
## Định nghĩa interface để Player đọc input
class_name PlayerController
extends Node

## Trả về hướng di chuyển (-1, 0, 1 cho X axis)
func get_move_direction() -> Vector2:
	return Vector2.ZERO

## Kiểm tra có nhấn nhảy không
func get_jump_input() -> bool:
	return false

## Kiểm tra có nhấn tấn công không
func get_attack_input() -> bool:
	return false

## Kiểm tra có nhấn dash không
func get_dash_input() -> bool:
	return false

## Kiểm tra có nhấn parry không
func get_parry_input() -> bool:
	return false

## Kiểm tra có nhấn special attack không
func get_special_input() -> bool:
	return false

## Lấy hướng joystick phải (cho aiming/rotation)
func get_right_stick() -> Vector2:
	return Vector2.ZERO

## Kiểm tra joystick phải có đang được nhấn không
func is_right_stick_pressed() -> bool:
	return false
