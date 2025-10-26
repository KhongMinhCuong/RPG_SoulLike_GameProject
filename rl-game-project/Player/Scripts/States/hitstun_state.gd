## HitstunState - Player bị hit và bị stun
## Plays "take_hit" animation
## Cannot be interrupted
## Reset combo
## Giảm tốc nhanh (x10)
class_name HitstunState
extends PlayerState

var hitstun_token: int = 0

func enter(_previous_state: PlayerState) -> void:
	hitstun_token = player._start_action(player.Action.HITSTUN)
	player._reset_combo()  # Reset combo khi bị hit
	
	player.play_animation(&"take_hit", true)
	
	await player.animated_sprite.animation_finished
	
	if hitstun_token != player._action_token:
		return  # Bị interrupt (unlikely)
	
	player._end_action(hitstun_token)
	
	# Return về state phù hợp
	if player.is_on_floor():
		get_parent().change_state("GroundedState")
	else:
		get_parent().change_state("AirState")

func physics_update(delta: float) -> void:
	# Giảm tốc nhanh (x10) khi bị hit
	var move_speed = player.base_stats.move_speed if player.base_stats else 180.0
	player.velocity.x = move_toward(player.velocity.x, 0.0, move_speed * 10.0 * delta)
	
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta

func handle_input(_controller: PlayerController) -> void:
	# Không thể làm gì trong lúc hitstun
	pass
