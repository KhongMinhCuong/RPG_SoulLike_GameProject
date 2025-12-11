## AirAttackState - Air attack (chỉ dùng 1 lần cho mỗi lần nhảy)
## Plays "air_atk" animation
## Cannot be interrupted
## Player bị freeze trên không (velocity = 0)
## Reset flag khi chạm đất
class_name AirAttackState
extends PlayerState

var attack_token: int = 0

func enter(_previous_state: PlayerState) -> void:
	player._air_attack_used = true  # Mark đã dùng air attack
	attack_token = player._start_action(player.Action.AIR_ATTACK)
	player._combo_buffered = false
	player._combo_accepting_buffer = false
	player._combo_window_timer = 0.0
	
	# Freeze trên không
	player.velocity = Vector2.ZERO
	
	# Play animation
	player.play_animation(player.AIR_ATTACK["anim"] as StringName, true)
	
	# Enable air attack hitbox (shape 3)
	if player.hitbox:
		player.hitbox.enable_shape(3)
	
	await player.animated_sprite.animation_finished
	
	if attack_token != player._action_token:
		return  # Bị interrupt
	
	player._reset_combo()
	player._end_action(attack_token)
	
	# Disable hitbox
	if player.hitbox:
		player.hitbox.disable()
	
	# Return về state phù hợp
	if player.is_on_floor():
		get_parent().change_state("GroundedState")
	else:
		get_parent().change_state("AirState")

func physics_update(_delta: float) -> void:
	# Không có physics trong air attack (frozen)
	pass

func handle_input(_controller: PlayerController) -> void:
	# Không thể làm gì trong lúc air attack
	pass
