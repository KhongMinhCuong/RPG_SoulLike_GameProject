## Base class cho tất cả Player States
class_name PlayerState
extends Node

## Reference đến player API
var player: Node  # PlayerAPI type

## Được gọi khi vào state này
func enter(_previous_state: PlayerState) -> void:
	pass

## Được gọi khi rời khỏi state này
func exit(_next_state: PlayerState) -> void:
	pass

## Được gọi mỗi physics frame
func physics_update(delta: float) -> void:
	pass

## Xử lý input từ controller
func handle_input(controller: PlayerController) -> void:
	pass

## Tên state để debug
func get_state_name() -> String:
	return get_script().get_path().get_file().get_basename()
