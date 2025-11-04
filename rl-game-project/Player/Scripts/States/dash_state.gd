## DashState - Dash action (trên đất hoặc trên không)
## Duration: dash_duration (0.2s default)
## Speed: dash_speed (400 default)
## Cannot be interrupted
class_name DashState
extends PlayerState

var dash_token: int = 0
var dash_direction: float = 0.0

func enter(_previous_state: PlayerState) -> void:
	dash_token = player._start_action(player.Action.DASH)
	
	# Calculate dash direction
	dash_direction = player.get_dash_direction(player.dash_direction.x)
	
	player.dash_performed.emit(dash_direction)
	var dash_speed = player.base_stats.dash_speed if player.base_stats else 400.0
	player.velocity.x = dash_direction * dash_speed
	player.play_animation(&"roll", true)
	
	# Wait cho dash kết thúc
	await player.get_tree().create_timer(player.dash_duration).timeout
	
	if dash_token != player._action_token:
		return  # Bị interrupt
	
	player._end_action(dash_token)
	
	# Return về state phù hợp
	if player.is_on_floor():
		get_parent().change_state("GroundedState")
	else:
		get_parent().change_state("AirState")

func physics_update(delta: float) -> void:
	# Maintain dash velocity
	# Apply gravity nếu đang trên không
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta

func handle_input(_controller: PlayerController) -> void:
	# Không thể làm gì trong lúc dash
	pass
