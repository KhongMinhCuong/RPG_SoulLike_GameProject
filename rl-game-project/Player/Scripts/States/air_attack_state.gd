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
	
	# Allow hitbox to deal damage during this attack
	player._allow_hitbox_activation = true
	
	# Freeze trên không
	player.velocity = Vector2.ZERO
	
	# Play animation via AnimationPlayer (controls hitbox via method tracks)
	var anim_name = player.AIR_ATTACK["anim"] as StringName
	
	if not player.animation_player or not player.animation_player.has_animation(anim_name):
		push_error("AnimationPlayer animation '%s' not found! Create it with method tracks." % anim_name)
		# Cleanup and exit
		player._allow_hitbox_activation = false
		player._end_action(attack_token)
		if player.is_on_floor():
			get_parent().change_state("GroundedState")
		else:
			get_parent().change_state("AirState")
		return
	
	player.animation_player.play(anim_name)
	await player.animation_player.animation_finished
	
	if attack_token != player._action_token:
		return  # Bị interrupt
	
	player._reset_combo()
	player._end_action(attack_token)
	
	# Prevent further damage from this attack
	player._allow_hitbox_activation = false
	
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
