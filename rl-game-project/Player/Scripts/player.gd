class_name Player extends CharacterBody2D

@export var speed : float = 200.0
@export var jump_velocity : float = -400.0
@export var gravity : float = 980.0
@export var dash_speed : float = 400.0
@export var dash_duration : float = 0.2
@export var max_health : float = 100.0

@export var joystick_left : VirtualJoystick
@export var joystick_right : VirtualJoystick
@export var touch_controls : TouchControls  # Now using TouchControls class

@onready var animated_sprite : AnimatedSprite2D = $Sprite2D
@onready var health_bar = $UI/HealthBar

var move_vector := Vector2.ZERO
var is_attacking := false
var is_jumping := false
var is_falling := false
var is_dashing := false
var is_parrying := false
var is_sp_attacking := false  # Track special attack state
var is_taking_damage := false  # Track damage state
var is_dead := false  # Track death state
var dash_direction := Vector2.ZERO
var has_air_attacked := false  # Track if air attack used this jump
var current_health : float = 0.0

# Test damage timer
var damage_timer : float = 0.0
var damage_interval : float = 1.0  # Damage every 1 second
var damage_per_second : float = 30.0

# Combo system
var combo_count : int = 0
var combo_window : float = 0.5  # Thời gian để nhấn tiếp cho combo
var combo_timer : float = 0.0
var can_combo : bool = false
var next_attack_queued : bool = false
var attack_locked : bool = false  # Prevent multiple attack calls

func _ready() -> void:
	if animated_sprite:
		animated_sprite.play("idle")
	
	# Initialize health
	current_health = max_health
	if health_bar:
		health_bar.init_health(max_health)
	
	# Connect to TouchControls signals
	if touch_controls:
		print("TouchControls found: ", touch_controls)
		touch_controls.attack_pressed.connect(_on_attack_pressed)
		touch_controls.dash_pressed.connect(_on_dash_pressed)
		touch_controls.parry_pressed.connect(_on_parry_pressed)
		touch_controls.sp_atk_pressed.connect(_on_sp_atk_pressed)
		print("Touch controls connected successfully!")
	else:
		print("WARNING: TouchControls not assigned!")

func _physics_process(delta: float) -> void:
	# Don't process if dead
	if is_dead:
		return
	
	# Test: Auto damage over time (30 damage per second)
	damage_timer += delta
	if damage_timer >= damage_interval:
		damage_timer = 0.0
		take_damage(damage_per_second)
	
	# Update combo timer ONLY when not attacking
	if combo_timer > 0 and not is_attacking:
		combo_timer -= delta
		if combo_timer <= 0:
			reset_combo()
	
	# Apply gravity (skip if air attacking or sp attacking)
	if not is_on_floor() and not (is_attacking and animated_sprite.animation == "air_atk") and not is_sp_attacking:
		velocity.y += gravity * delta
		is_falling = velocity.y > 0
		is_jumping = velocity.y < 0
	else:
		is_falling = false
		is_jumping = false
		# Reset air attack when landing
		if is_on_floor():
			has_air_attacked = false
	
	# Handle jump
	if Input.is_action_just_pressed("ui_up") and is_on_floor() and not is_attacking and not is_dashing:
		velocity.y = jump_velocity
		is_jumping = true
	
	# Horizontal movement (skip if dashing, air attacking, sp attacking, or movement locked)
	if not is_dashing and not is_sp_attacking and not is_taking_damage and not (is_attacking and animated_sprite.animation == "air_atk") and not is_movement_locked():
		var direction = Input.get_axis("ui_left", "ui_right")
		
		if direction != 0:
			velocity.x = direction * speed
			# Store last movement direction for dash
			dash_direction.x = direction
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
	elif is_movement_locked() or is_sp_attacking or is_taking_damage:
		# Stop movement when locked or sp attacking or taking damage
		velocity.x = move_toward(velocity.x, 0, speed * 2)  # Faster deceleration
	
	# Handle animations
	handle_animations()
	
	# Handle sprite flip based on movement direction
	if not is_dashing and velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0
	
	# Rotation (for joystick right - optional)
	if joystick_right and joystick_right.is_pressed:
		rotation = joystick_right.output.angle()
	
	# Attack input (keyboard)
	if Input.is_action_just_pressed("ui_accept"):
		if not is_attacking and not is_dashing:
			attack()
		elif can_combo:
			# Queue next attack in combo
			next_attack_queued = true
	
	# Dash input (keyboard - use Shift) - Can cancel attacks and parry
	if Input.is_action_just_pressed("ui_cancel") and not is_dashing:
		dash()
	
	# Move the character
	move_and_slide()

func handle_animations() -> void:
	if is_attacking or is_dashing or is_parrying or is_sp_attacking or is_taking_damage or is_dead:
		return # Don't change animation during special actions
	
	# Check if in air
	if not is_on_floor():
		if is_jumping:
			# Jumping up
			if animated_sprite.animation != "j_up":
				animated_sprite.play("j_up")
		elif is_falling:
			# Falling down
			if animated_sprite.animation != "j_down":
				animated_sprite.play("j_down")
	else:
		# On ground
		if velocity.x != 0:
			# Running
			if animated_sprite.animation != "run":
				animated_sprite.play("run")
		else:
			# Idle
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")

func attack() -> void:
	if is_attacking or attack_locked or is_sp_attacking:
		return
	
	# Check if attacking in the air
	if not is_on_floor():
		air_attack()
		return
	
	attack_locked = true
	is_attacking = true
	can_combo = false
	next_attack_queued = false
	combo_timer = 0.0  # Clear timer when starting new attack
	
	# Increment combo ONLY at the start of attack
	combo_count += 1
	if combo_count > 3:
		combo_count = 1
	
	var current_combo = combo_count  # Store current combo number
	
	# Play appropriate attack animation
	var attack_anim = ""
	match current_combo:
		1:
			attack_anim = "1_atk"
		2:
			attack_anim = "2_atk"
		3:
			attack_anim = "3_atk"
	
	animated_sprite.play(attack_anim)
	
	# Wait a bit before allowing combo input (about 60-70% through animation)
	var anim_length = animated_sprite.sprite_frames.get_frame_count(attack_anim) / animated_sprite.sprite_frames.get_animation_speed(attack_anim)
	await get_tree().create_timer(anim_length * 0.6).timeout
	
	# Now player can input next attack
	can_combo = true
	combo_timer = combo_window
	
	# Wait for animation to finish
	await animated_sprite.animation_finished
	
	is_attacking = false
	can_combo = false
	attack_locked = false  # Unlock for next attack
	
	# Check if next attack was queued
	if next_attack_queued and current_combo < 3:
		# Continue to next combo
		attack()
	elif current_combo < 3:
		# No combo input, play ending animation
		play_attack_end(current_combo)
	else:
		# Combo 3 finished (already has ending built in)
		# Start combo timer for next attack sequence
		combo_timer = combo_window

func air_attack() -> void:
	if is_attacking or attack_locked or has_air_attacked or is_sp_attacking:
		return
	
	attack_locked = true
	is_attacking = true
	has_air_attacked = true  # Mark that air attack is used
	
	# Stop all movement (đứng im trên không)
	velocity = Vector2.ZERO
	
	# Play air attack animation
	animated_sprite.play("air_atk")
	
	# Wait for animation to finish
	await animated_sprite.animation_finished
	
	is_attacking = false
	attack_locked = false
	
	# Reset combo when landing from air attack
	reset_combo()

func play_attack_end(combo_num: int) -> void:
	var end_anim = ""
	match combo_num:
		1:
			end_anim = "1_atk_end"
		2:
			end_anim = "2_atk_end"
	
	if end_anim != "":
		is_attacking = true  # Lock animation during ending
		animated_sprite.play(end_anim)
		await animated_sprite.animation_finished
		is_attacking = false  # Unlock after ending completes
	
	# Only reset if player hasn't started a new attack
	if not is_attacking:
		reset_combo()

func reset_combo() -> void:
	combo_count = 0
	combo_timer = 0.0
	can_combo = false
	next_attack_queued = false

func is_animation_cancelable() -> bool:
	# Check if current animation can be canceled by dash
	var current_anim = animated_sprite.animation
	return current_anim in ["1_atk", "2_atk", "3_atk", "1_atk_end", "2_atk_end", "defend"]

func is_movement_locked() -> bool:
	# Check if player cannot move (during ground attacks or parry)
	var current_anim = animated_sprite.animation
	return (is_attacking or is_parrying) and current_anim in ["1_atk", "2_atk", "3_atk", "1_atk_end", "2_atk_end", "defend"]

func special_attack() -> void:
	if is_sp_attacking or is_attacking or is_dashing or is_parrying:
		return
	
	is_sp_attacking = true
	
	# Freeze completely in place (both X and Y)
	velocity = Vector2.ZERO
	
	# Play special attack animation
	animated_sprite.play("sp_atk")
	
	# Wait for animation to finish
	await animated_sprite.animation_finished
	
	is_sp_attacking = false

func take_damage(damage: float) -> void:
	if is_dead or is_taking_damage:
		return
	
	# Reduce health
	current_health -= damage
	if health_bar:
		health_bar.health = current_health
	
	# Check if dead
	if current_health <= 0:
		die()
		return
	
	# Play take hit animation
	is_taking_damage = true
	animated_sprite.play("take_hit")
	
	# Wait for animation to finish
	await animated_sprite.animation_finished
	
	is_taking_damage = false

func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	
	# Reset all states
	is_attacking = false
	is_dashing = false
	is_parrying = false
	is_sp_attacking = false
	is_taking_damage = false
	
	# Stop all movement
	velocity = Vector2.ZERO
	
	# Play death animation
	animated_sprite.play("death")
	
	# Wait for death animation to finish
	await animated_sprite.animation_finished
	
	# Optionally: reload scene, show game over, etc.
	print("Player died!")
	# get_tree().reload_current_scene()  # Uncomment to reload

func heal(amount: float) -> void:
	if is_dead:
		return
	
	current_health = min(current_health + amount, max_health)
	if health_bar:
		health_bar.health = current_health

func dash() -> void:
	if is_dashing or is_sp_attacking:  # Cannot dash during special attack
		return
	
	# Cancel attack or parry if animation is cancelable
	if is_animation_cancelable():
		is_attacking = false
		is_parrying = false
		attack_locked = false
		can_combo = false
		next_attack_queued = false
	
	is_dashing = true
	
	# Get current input direction (prioritize current joystick input)
	var current_direction = Input.get_axis("ui_left", "ui_right")
	var dash_dir = 0.0
	
	if current_direction != 0:
		# Dash in current joystick direction
		dash_dir = current_direction
	elif dash_direction.x != 0:
		# Use last movement direction if no current input
		dash_dir = dash_direction.x
	else:
		# Use face direction as fallback
		dash_dir = -1 if animated_sprite.flip_h else 1
	
	# Play dash animation (roll)
	animated_sprite.play("roll")
	
	# Apply dash velocity
	velocity.x = dash_dir * dash_speed
	
	# Wait for dash duration
	await get_tree().create_timer(dash_duration).timeout
	
	is_dashing = false

func parry() -> void:
	if is_parrying or is_attacking or is_dashing or is_sp_attacking:
		return
	
	is_parrying = true
	animated_sprite.play("defend")
	
	# Wait for animation to finish
	await animated_sprite.animation_finished
	is_parrying = false

# Touch button callbacks
func _on_attack_pressed() -> void:
	if not is_attacking and not is_dashing:
		attack()
	elif can_combo:
		# Queue next attack in combo
		next_attack_queued = true

func _on_dash_pressed() -> void:
	if not is_dashing:
		dash()

func _on_parry_pressed() -> void:
	if not is_parrying:
		parry()

func _on_sp_atk_pressed() -> void:
	if not is_sp_attacking:
		special_attack()
