## ParryState - Parry/Defend action
## Plays "defend" animation
## Cannot be interrupted
## Giảm tốc nhanh (x10)
class_name ParryState
extends PlayerState

var parry_token: int = 0

func enter(_previous_state: PlayerState) -> void:
	parry_token = player._start_action(player.Action.PARRY)
	player.play_animation(&"defend", true)
	
	await player.animated_sprite.animation_finished
	
	if parry_token != player._action_token:
		return  # Bị interrupt
	
	player._end_action(parry_token)
	
	# Return về state phù hợp
	if player.is_on_floor():
		get_parent().change_state("GroundedState")
	else:
		get_parent().change_state("AirState")

func physics_update(delta: float) -> void:
	# Giảm tốc nhanh (x10) khi parry
	var move_speed = player.base_stats.move_speed if player.base_stats else 180.0
	player.velocity.x = move_toward(player.velocity.x, 0.0, move_speed * 10.0 * delta)
	
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta

func handle_input(_controller: PlayerController) -> void:
	# Không thể làm gì trong lúc parry
	pass
