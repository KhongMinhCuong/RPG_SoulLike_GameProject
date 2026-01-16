## ArcherAttackState - Attack state cho Archer
## Spawn projectile từ hitbox center khi attack
## Combo 1, 2, 3 và air_atk spawn arrow; sp_atk dùng hitbox thường
class_name ArcherAttackState
extends PlayerState

var attack_token: int = 0
var projectile_spawner: Node = null
var combo_speed_passive = null

func enter(_previous_state: PlayerState) -> void:
	# Find ProjectileSpawner
	projectile_spawner = player.get_node_or_null("ProjectileSpawner")
	
	# Find combo speed passive
	_find_combo_passive()
	
	# Close combo window từ lần attack trước
	if _previous_state and _previous_state.get_state_name() == "archer_attack_state":
		player._combo_accepting_buffer = false
		player._combo_buffered = false
	
	_execute_attack()

func _find_combo_passive() -> void:
	# Skip if already found
	if combo_speed_passive:
		return
	
	print("[ArcherAttack] Looking for combo passive...")
	var ability_mgr = player.get_node_or_null("AbilityManager")
	if not ability_mgr:
		print("[ArcherAttack] AbilityManager not found!")
		return
	
	print("[ArcherAttack] Searching for Rapid Fire passive in %d passives" % ability_mgr.passives.size())
	for passive in ability_mgr.passives:
		print("[ArcherAttack] Found passive: %s" % passive.passive_name)
		if passive.passive_name == "Rapid Fire":
			combo_speed_passive = passive
			print("[ArcherAttack] Rapid Fire passive ASSIGNED!")
			return
	
	print("[ArcherAttack] WARNING: Rapid Fire passive NOT found!")

func _execute_attack() -> void:
	# Xác định combo step
	if player._combo_window_timer <= 0.0:
		player._combo_step = 0
	else:
		player._combo_step = clamp(player._combo_step + 1, 0, player.GROUND_COMBO.size() - 1)
	
	player._combo_window_timer = 0.0
	var step = player._combo_step
	var data: Dictionary = player.GROUND_COMBO[step]
	
	# Start action
	attack_token = player._start_action(player.Action.ATTACK)
	player._combo_buffered = false
	player.combo_step_started.emit(step)
	
	# Get attack speed multiplier từ passive
	var speed_mult = 1.0
	if combo_speed_passive and combo_speed_passive.has_method("get_attack_speed_multiplier"):
		speed_mult = combo_speed_passive.get_attack_speed_multiplier()
	
	# Play animation với speed multiplier
	var anim_name: StringName = data["anim"] as StringName
	var using_animation_player := false
	
	if player.animation_player and player.animation_player.has_animation(anim_name):
		player.animation_player.speed_scale = speed_mult
		player.animation_player.play(anim_name)
		using_animation_player = true
	elif player.animated_sprite:
		player.animated_sprite.speed_scale = speed_mult
		player.play_animation(anim_name, true)
	
	# Wait đến buffer_ratio% để spawn arrow
	var anim_length: float
	if using_animation_player:
		anim_length = player.animation_player.get_animation(anim_name).length
	else:
		anim_length = player._get_animation_length(anim_name)
	
	if anim_length > 0.0:
		var buffer_ratio := float(data.get("buffer_ratio", 0.6))
		# Adjust for speed multiplier
		await player.get_tree().create_timer((anim_length * buffer_ratio) / speed_mult).timeout
	
	if attack_token != player._action_token:
		_reset_animation_speed()
		return
	
	# SPAWN ARROW tại thời điểm này (hitbox activation moment)
	_spawn_arrow()
	
	# Mở combo window
	player._combo_accepting_buffer = true
	player._combo_window_timer = player.combo_window
	
	# Wait cho animation kết thúc
	if using_animation_player:
		await player.animation_player.animation_finished
	else:
		await player.animated_sprite.animation_finished
	
	if attack_token != player._action_token:
		_reset_animation_speed()
		return
	
	# Check combo buffer
	if player._combo_step < player.GROUND_COMBO.size() - 1 and player._combo_buffered:
		player._combo_buffered = false
		player._action_token += 1
		_execute_attack()
		return
	
	# Nếu hoàn thành 3_atk (step 2), trigger passive
	if step == 2 and combo_speed_passive:
		combo_speed_passive.on_combo_completed()
	
	# Play end animation (nếu có)
	var end_anim: StringName = data.get("end_anim", &"") as StringName
	if end_anim != &"":
		# Ưu tiên AnimatedSprite cho end animations (vì 1_atk_end, 2_atk_end chỉ có trong sprite frames)
		if player.animated_sprite and player.animated_sprite.sprite_frames.has_animation(end_anim):
			player.play_animation(end_anim, true)
			await player.animated_sprite.animation_finished
		elif using_animation_player and player.animation_player.has_animation(end_anim):
			player.animation_player.play(end_anim)
			await player.animation_player.animation_finished
		else:
			# Fallback nếu không tìm thấy end_anim
			await player.get_tree().create_timer(0.2 / speed_mult).timeout
	else:
		# Không có end_anim (như 3_atk) - wait một chút
		await player.get_tree().create_timer(0.2 / speed_mult).timeout
	
	if attack_token != player._action_token:
		_reset_animation_speed()
		return
	
	# End attack
	player._end_action(attack_token)
	player._combo_accepting_buffer = false
	player._reset_combo()
	
	_reset_animation_speed()
	
	# Return to appropriate state
	if player.is_on_floor():
		get_parent().change_state("GroundedState")
	else:
		get_parent().change_state("AirState")

func _spawn_arrow() -> void:
	"""Spawn arrow từ hitbox center"""
	if not projectile_spawner:
		push_warning("[ArcherAttackState] ProjectileSpawner not found!")
		return
	
	projectile_spawner.spawn_combo_arrow()

func _reset_animation_speed() -> void:
	if player.animation_player:
		player.animation_player.speed_scale = 1.0
	if player.animated_sprite:
		player.animated_sprite.speed_scale = 1.0

func physics_update(delta: float) -> void:
	# Slow movement while attacking
	if player.is_on_floor():
		# Prevent horizontal movement during ground combo attacks (1_atk/2_atk/3_atk)
		# Force horizontal velocity to zero so player remains stationary.
		player.velocity.x = 0
	else:
		player.velocity.y += player.gravity * delta

func handle_input(controller: PlayerController) -> void:
	# Buffer attack input
	if controller.get_attack_input() and player._combo_accepting_buffer:
		player._combo_buffered = true
	
	# Dash cancel
	if controller.get_dash_input() and player.can_dash() and player._combo_accepting_buffer:
		_reset_animation_speed()
		get_parent().change_state("DashState")

func exit(_next_state: PlayerState) -> void:
	_reset_animation_speed()

func get_state_name() -> String:
	return "archer_attack_state"
