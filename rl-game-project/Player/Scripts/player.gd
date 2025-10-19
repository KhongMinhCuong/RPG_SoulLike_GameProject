extends "res://Player/Scripts/player_api.gd"
class_name Player

func _ready() -> void:
	current_health = max_health
	if animated_sprite:
		animated_sprite.play(&"idle")
	if health_bar:
		health_bar.init_health(max_health)
		health_bar.health = current_health
	health_changed.emit(current_health, max_health)
	if touch_controls:
		touch_controls.attack_pressed.connect(_on_attack_pressed)
		touch_controls.dash_pressed.connect(_on_dash_pressed)
		touch_controls.parry_pressed.connect(_on_parry_pressed)
		touch_controls.sp_atk_pressed.connect(_on_sp_atk_pressed)
	else:
		push_warning("TouchControls not assigned to Player.")

func _physics_process(delta: float) -> void:
	if current_action == Action.DEAD:
		return

	_update_combo_timer(delta)
	_apply_gravity(delta)
	_handle_jump_input()
	_handle_horizontal_input()
	_handle_action_input()
	_update_sprite_orientation()
	_update_animations()

	move_and_slide()

func _handle_horizontal_input() -> void:
	if current_action == Action.DASH:
		return

	var direction := Input.get_axis("ui_left", "ui_right")
	move_vector.x = direction

	if _can_move():
		if direction != 0.0:
			velocity.x = direction * speed
			_last_move_direction = direction
			dash_direction.x = direction
		else:
			velocity.x = move_toward(velocity.x, 0.0, speed)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 2.0)

func _handle_jump_input() -> void:
	if Input.is_action_just_pressed("ui_up") and is_on_floor() and _can_perform_basic_action():
		velocity.y = jump_velocity

func _handle_action_input() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		request_attack()
	if Input.is_action_just_pressed("ui_cancel"):
		request_dash()

func _apply_gravity(delta: float) -> void:
	var air_control_locked := current_action in [Action.AIR_ATTACK, Action.SPECIAL]
	if not is_on_floor():
		if not air_control_locked:
			velocity.y += gravity * delta
	else:
		_air_attack_used = false
		if velocity.y > 0.0:
			velocity.y = 0.0

func _update_sprite_orientation() -> void:
	if joystick_right and joystick_right.is_pressed:
		rotation = joystick_right.output.angle()
	elif abs(velocity.x) > 0.01 and current_action != Action.DASH:
		animated_sprite.flip_h = velocity.x < 0.0

func _update_animations() -> void:
	if current_action in [Action.ATTACK, Action.AIR_ATTACK, Action.DASH, Action.PARRY, Action.SPECIAL, Action.HITSTUN]:
		return

	if not is_on_floor():
		if velocity.y < 0.0:
			_play_animation_if_needed(&"j_up")
		else:
			_play_animation_if_needed(&"j_down")
	elif abs(velocity.x) > 0.01:
		_play_animation_if_needed(&"run")
	else:
		_play_animation_if_needed(&"idle")

func _update_combo_timer(delta: float) -> void:
	if _combo_window_timer <= 0.0:
		return

	_combo_window_timer -= delta
	if _combo_window_timer <= 0.0:
		_reset_combo()

func _begin_ground_attack(step: int) -> void:
	var data: Dictionary = GROUND_COMBO[step]
	var token := _start_action(Action.ATTACK)
	_combo_buffered = false
	_combo_accepting_buffer = false
	combo_step_started.emit(step)

	var anim_name: StringName = data["anim"] as StringName
	animated_sprite.play(anim_name)

	var anim_length := _get_animation_length(anim_name)
	if anim_length > 0.0:
		var buffer_ratio := float(data.get("buffer_ratio", 0.6))
		await get_tree().create_timer(anim_length * buffer_ratio).timeout
	if token != _action_token:
		return

	_combo_accepting_buffer = true
	_combo_window_timer = combo_window

	await animated_sprite.animation_finished
	if token != _action_token:
		return

	_combo_accepting_buffer = false

	if step < GROUND_COMBO.size() - 1 and _combo_buffered:
		_combo_buffered = false
		_end_action(token)
		call_deferred("request_attack")
		return

	var end_anim: StringName = data.get("end_anim", &"") as StringName
	if end_anim != &"":
		animated_sprite.play(end_anim)
		await animated_sprite.animation_finished
		if token != _action_token:
			return

	if step >= GROUND_COMBO.size() - 1:
		_reset_combo()

	_end_action(token)

func _begin_air_attack() -> void:
	_air_attack_used = true
	var token := _start_action(Action.AIR_ATTACK)
	_combo_buffered = false
	_combo_accepting_buffer = false
	_combo_window_timer = 0.0
	velocity = Vector2.ZERO
	animated_sprite.play(AIR_ATTACK["anim"] as StringName)
	await animated_sprite.animation_finished
	if token != _action_token:
		return
	_reset_combo()
	_end_action(token)

func _start_dash(direction: float) -> void:
	var token := _start_action(Action.DASH)
	dash_performed.emit(direction)
	velocity.x = direction * dash_speed
	animated_sprite.play(&"roll")
	await get_tree().create_timer(dash_duration).timeout
	if token != _action_token:
		return
	_end_action(token)

func _get_animation_length(anim_name: StringName) -> float:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return 0.0

	var frames := animated_sprite.sprite_frames
	var frame_count := frames.get_frame_count(anim_name)
	var anim_speed := frames.get_animation_speed(anim_name)
	if frame_count <= 0 or anim_speed <= 0.0:
		return 0.0

	return frame_count / anim_speed

func _play_animation_if_needed(anim_name: StringName) -> void:
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func _can_move() -> bool:
	return current_action not in [Action.ATTACK, Action.AIR_ATTACK, Action.DASH, Action.PARRY, Action.SPECIAL, Action.HITSTUN, Action.DEAD]

func _can_perform_basic_action() -> bool:
	return current_action == Action.NONE

func _can_cancel_with_dash() -> bool:
	return current_action == Action.ATTACK and _combo_accepting_buffer

func _die() -> void:
	_interrupt_current_action()
	velocity = Vector2.ZERO
	_action_token += 1
	current_action = Action.DEAD
	died.emit()
	animated_sprite.play(&"death")
	await animated_sprite.animation_finished
