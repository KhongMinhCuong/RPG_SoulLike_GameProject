## GroundedState - Player đang đứng yên hoặc di chuyển trên mặt đất
## Handles: Movement, Jump, và tất cả action inputs
class_name GroundedState
extends PlayerState

func enter(_previous_state: PlayerState) -> void:
	# Reset air attack flag khi chạm đất
	player._air_attack_used = false

func physics_update(_delta: float) -> void:
	# Check rơi khỏi platform
	if not player.is_on_floor():
		get_parent().change_state("AirState")
		return
	
	# Reset velocity Y khi đứng trên đất
	if player.velocity.y > 0.0:
		player.velocity.y = 0.0

func handle_input(controller: PlayerController) -> void:
	# === MOVEMENT ===
	var move_input = controller.get_move_direction()
	var direction = move_input.x
	
	if direction != 0.0:
		var move_speed = player.base_stats.move_speed if player.base_stats else 180.0
		player.velocity.x = direction * move_speed
		player._last_move_direction = direction
		player.dash_direction.x = direction
		player.animated_sprite.flip_h = direction < 0.0
	else:
		# Decelerate nhanh hơn (10x) khi không có input
		var move_speed = player.base_stats.move_speed if player.base_stats else 180.0
		player.velocity.x = move_toward(player.velocity.x, 0.0, move_speed * 10.0 * get_physics_process_delta_time())
	
	# === JUMP ===
	if controller.get_jump_input():
		player.velocity.y = player.jump_velocity
		get_parent().change_state("AirState")
		return
	
	# === ATTACK ===
	if controller.get_attack_input():
		if player.can_attack():
			get_parent().change_state("AttackState")
		return
	
	# === DASH ===
	if controller.get_dash_input():
		if player.can_dash():
			# Update dash direction
			if move_input.x != 0.0:
				player.dash_direction.x = move_input.x
			# Enforce cooldown via runtime_stats
			if player.runtime_stats and player.runtime_stats.can_use_ability("dash"):
				player.runtime_stats.use_ability("dash")
				get_parent().change_state("DashState")
			else:
				# Cooldown active - ignore dash
				return
		return
	
	# === PARRY ===
	if controller.get_parry_input():
		if player.can_parry():
			if player.runtime_stats and player.runtime_stats.can_use_ability("parry"):
				player.runtime_stats.use_ability("parry")
				get_parent().change_state("ParryState")
			else:
				return
		return
	
	# === SPECIAL ===
	if controller.get_special_input():
		if player.can_special():
			if player.runtime_stats and player.runtime_stats.can_use_ability("special"):
				player.runtime_stats.use_ability("special")
				get_parent().change_state("SpecialState")
			else:
				return
		return
	
	# === ANIMATION ===
	if abs(player.velocity.x) > 0.01:
		player.play_animation(&"run")
	else:
		player.play_animation(&"idle")
