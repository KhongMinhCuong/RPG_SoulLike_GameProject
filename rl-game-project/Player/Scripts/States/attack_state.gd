## AttackState - Xử lý ground combo với dash cancel
## Features:
## - 3-hit combo chain với end animations
## - Combo buffer system (buffer_ratio = 60-65%)
## - Dash cancel được trong toàn bộ combo window
## - Token-based async safety
class_name AttackState
extends PlayerState

func enter(_previous_state: PlayerState) -> void:
	# Close combo window từ lần attack trước (nếu re-enter từ chính state này)
	if _previous_state and _previous_state.get_state_name() == "attack_state":
		player._combo_accepting_buffer = false
		player._combo_buffered = false
	
	_execute_attack()

func _execute_attack() -> void:
	# Local token để track THIS execution path only
	var attack_token: int
	
	# Xác định combo step
	if player._combo_window_timer <= 0.0:
		player._combo_step = 0  # Bắt đầu combo mới
	else:
		player._combo_step = clamp(player._combo_step + 1, 0, player.GROUND_COMBO.size() - 1)
	
	player._combo_window_timer = 0.0
	var step = player._combo_step
	var data: Dictionary = player.GROUND_COMBO[step]
	
	# Start action và lấy token MỚI
	attack_token = player._start_action(player.Action.ATTACK)
	player._combo_buffered = false
	# KHÔNG reset accepting_buffer ở đây - giữ window open liên tục khi continue combo
	player.combo_step_started.emit(step)
	
	# Allow hitbox to deal damage during this attack
	player._allow_hitbox_activation = true
	
	# Play animation via AnimationPlayer (controls hitbox via method tracks)
	var anim_name: StringName = data["anim"] as StringName
	if not player.animation_player or not player.animation_player.has_animation(anim_name):
		push_error("AnimationPlayer animation '%s' not found! Create it with method tracks." % anim_name)
		# Cleanup and exit
		player._allow_hitbox_activation = false
		player._end_action(attack_token)
		get_parent().change_state("GroundedState")
		return
	
	player.animation_player.play(anim_name)
	
	# Wait đến buffer_ratio% của animation
	var anim_length: float = player._get_animation_length(anim_name)
	if anim_length > 0.0:
		var buffer_ratio := float(data.get("buffer_ratio", 0.6))
		await player.get_tree().create_timer(anim_length * buffer_ratio).timeout
	
	if attack_token != player._action_token:
		# Attack was interrupted - prevent any further damage
		player._allow_hitbox_activation = false
		if player.hitbox:
			player.hitbox.disable()
		return
	
	# Mở combo window - từ đây player có thể buffer attack HOẶC dash cancel
	player._combo_accepting_buffer = true
	player._combo_window_timer = player.combo_window
	
	# Wait cho main animation kết thúc
	await player.animated_sprite.animation_finished
	
	if attack_token != player._action_token:
		return  # Bị interrupt
	
	# KEEP combo window open - dash cancel vẫn available!
	
	# Check nếu có buffer attack input
	if player._combo_step < player.GROUND_COMBO.size() - 1 and player._combo_buffered:
		player._combo_buffered = false
		# Increment token để invalidate OLD execution path
		player._action_token += 1
		# Continue combo - accepting_buffer VẪN MỞ từ trước!
		_execute_attack()
		return
	
	# Play end animation (nếu có) - window vẫn open
	var current_step = player._combo_step
	var current_data: Dictionary = player.GROUND_COMBO[current_step]
	var end_anim: StringName = current_data.get("end_anim", &"") as StringName
	
	if end_anim != &"":
		player.play_animation(end_anim, true)
		# Window vẫn open - có thể dash cancel end animation!
		await player.animated_sprite.animation_finished
		if attack_token != player._action_token:
			return
	else:
		# Không có end animation (như 3_atk) - delay 0.2s cho dash cancel window
		await player.get_tree().create_timer(0.2).timeout
		if attack_token != player._action_token:
			# Attack was interrupted - prevent any further damage
			player._allow_hitbox_activation = false
			if player.hitbox:
				player.hitbox.disable()
			return
	
	# Close combo window SAU KHI hết tất cả animations
	player._combo_accepting_buffer = false
	
	# Reset combo nếu là đòn cuối
	if player._combo_step >= player.GROUND_COMBO.size() - 1:
		player._reset_combo()
	
	player._end_action(attack_token)
	
	# Prevent further damage from this attack (even if animation continues)
	player._allow_hitbox_activation = false
	
	# Return về state phù hợp
	if player.is_on_floor():
		get_parent().change_state("GroundedState")
	else:
		get_parent().change_state("AirState")

func physics_update(delta: float) -> void:
	# Giảm tốc nhanh (x10) khi attack để không trượt xa
	var move_speed = player.base_stats.move_speed if player.base_stats else 180.0
	player.velocity.x = move_toward(player.velocity.x, 0.0, move_speed * 10.0 * delta)
	
	# Apply gravity nếu rơi khỏi platform
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta

func handle_input(controller: PlayerController) -> void:
	# Buffer combo input - CHỈ ACCEPT INPUT ĐẦU TIÊN
	if controller.get_attack_input() and player._combo_accepting_buffer and not player._combo_buffered:
		player._combo_buffered = true
		# KHÔNG đóng window - vẫn cho phép dash cancel!
	
	# Dash cancel - có thể cancel trong toàn bộ combo window
	if controller.get_dash_input() and player._combo_accepting_buffer:
		# Update dash direction theo input hiện tại
		var move_input = controller.get_move_direction()
		if move_input.x != 0.0:
			player.dash_direction.x = move_input.x
		# Enforce cooldown before allowing dash-cancel
		if player.runtime_stats and player.runtime_stats.can_use_ability("dash"):
			player.runtime_stats.use_ability("dash")
			player._interrupt_current_action()
			player._reset_combo()
			get_parent().change_state("DashState")
		else:
			# Cooldown active - ignore dash cancel
			return

func exit(_next_state: PlayerState) -> void:
	# Combo timer được update ở player._physics_process
	pass
