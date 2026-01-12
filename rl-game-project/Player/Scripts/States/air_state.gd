## AirState - Player đang ở trên không (jumping/falling)
## Handles: Air control (70%), Air attack (1 lần), Air dash
class_name AirState
extends PlayerState

func physics_update(delta: float) -> void:
	# Apply gravity
	player.velocity.y += player.gravity * delta
	
	# Check landed
	if player.is_on_floor():
		get_parent().change_state("GroundedState")
		return
	
	# Update animation theo velocity
	if player.velocity.y < 0.0:
		player.play_animation(&"j_up")  # Đang bay lên
	else:
		player.play_animation(&"j_down")  # Đang rơi xuống

func handle_input(controller: PlayerController) -> void:
	# === AIR CONTROL ===
	var move_input = controller.get_move_direction()
	var direction = move_input.x
	
	if direction != 0.0:
		var move_speed = player.base_stats.move_speed if player.base_stats else 180.0
		player.velocity.x = direction * move_speed * 0.7  # 70% control trên không
		player.animated_sprite.flip_h = direction < 0.0
	
	# === AIR ATTACK ===
	if controller.get_attack_input() and player.can_air_attack():
		# Enforce cooldown for air attack
		if player.runtime_stats and player.runtime_stats.can_use_ability("air_attack"):
			player.runtime_stats.use_ability("air_attack")
			get_parent().change_state("AirAttackState")
		else:
			return
		return
	
	# === AIR DASH ===
	if controller.get_dash_input() and player.can_dash():
		# Update dash direction
		if direction != 0.0:
			player.dash_direction.x = direction
		# Enforce cooldown
		if player.runtime_stats and player.runtime_stats.can_use_ability("dash"):
			player.runtime_stats.use_ability("dash")
			get_parent().change_state("DashState")
		else:
			return
		return
	
	# === SPECIAL ATTACK (allowed in air) ===
	if controller.get_special_input():
		if player.can_special():
			if player.runtime_stats and player.runtime_stats.can_use_ability("special"):
				player.runtime_stats.use_ability("special")
				get_parent().change_state("SpecialState")
			else:
				return
		return
	
	# Consume parry input (không available trên không)
	if controller.get_parry_input():
		pass  # Ignore
