## Quản lý chuyển đổi giữa các state
class_name PlayerStateMachine
extends Node

signal state_changed(from: String, to: String)

@export var initial_state: PlayerState

var current_state: PlayerState
var states: Dictionary = {}
var player: Node  # PlayerAPI

func _ready() -> void:
	# Đợi player setup xong
	await owner.ready
	
	# Lấy reference đến player
	player = owner
	
	# Thu thập tất cả state children
	for child in get_children():
		if child is PlayerState:
			states[child.name] = child
			child.player = player
	
	# Khởi tạo state ban đầu
	if initial_state:
		current_state = initial_state
	elif not states.is_empty():
		# Nếu không có initial_state, chọn state đầu tiên
		# Ưu tiên GroundedState nếu có
		if states.has("GroundedState"):
			current_state = states["GroundedState"]
		else:
			current_state = states.values()[0]
	
	if current_state:
		current_state.enter(null)
	else:
		push_error("[StateMachine] No states found! Add state nodes as children of StateMachine.")

## Chuyển sang state mới
func change_state(new_state_name: String) -> void:
	if not states.has(new_state_name):
		push_warning("State '%s' not found!" % new_state_name)
		return
	
	var new_state: PlayerState = states[new_state_name]
	if new_state == current_state:
		return
	
	var previous_state = current_state
	
	# Exit state cũ
	if current_state:
		current_state.exit(new_state)
	
	# Enter state mới
	current_state = new_state
	current_state.enter(previous_state)
	
	# Phát signal
	var from_name = previous_state.get_state_name() if previous_state else "none"
	var to_name = current_state.get_state_name()
	state_changed.emit(from_name, to_name)

## Update state hiện tại
func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

## Xử lý input
func handle_input(controller: PlayerController) -> void:
	if current_state:
		current_state.handle_input(controller)

## Lấy state hiện tại
func get_current_state_name() -> String:
	return current_state.get_state_name() if current_state else "none"
