## RangedAttackState - Ranged attack cho Archer
## Spawn projectile thay vì melee attack
## Sử dụng ProjectileSpawner để bắn
class_name RangedAttackState
extends PlayerState

var attack_token: int = 0
var projectile_spawner: Node = null

func enter(_previous_state: PlayerState) -> void:
	attack_token = player._start_action(player.Action.ATTACK)
	
	# Find ProjectileSpawner
	projectile_spawner = player.get_node_or_null("ProjectileSpawner")
	
	# Play shoot animation
	_execute_ranged_attack()

func _execute_ranged_attack() -> void:
	# Play bow animation (dùng 1_atk hoặc tạo animation riêng)
	var anim_name = &"1_atk"  # Có thể thay bằng "shoot" animation
	
	if player.animation_player and player.animation_player.has_animation(anim_name):
		player.animation_player.play(anim_name)
	elif player.animated_sprite:
		player.play_animation(anim_name)
	
	# Spawn arrow sau delay nhỏ (để sync với animation)
	await player.get_tree().create_timer(0.15).timeout
	
	if attack_token != player._action_token:
		return  # Bị interrupt
	
	# Spawn projectile
	_spawn_arrow()
	
	# Wait for animation to finish
	if player.animation_player:
		await player.animation_player.animation_finished
	else:
		await player.animated_sprite.animation_finished
	
	if attack_token != player._action_token:
		return
	
	# End attack
	player._end_action(attack_token)
	
	# Return to appropriate state
	if player.is_on_floor():
		get_parent().change_state("GroundedState")
	else:
		get_parent().change_state("AirState")

func _spawn_arrow() -> void:
	# Get direction
	var direction = Vector2.RIGHT if player.direction >= 0 else Vector2.LEFT
	
	# Use ProjectileSpawner if available
	if projectile_spawner and projectile_spawner.has_method("spawn_projectile"):
		projectile_spawner.spawn_projectile(direction)
		print("[RangedAttackState] Arrow spawned via ProjectileSpawner")
		return
	
	# Fallback: Manual spawn
	var arrow_scene = preload("res://Player/Scenes/Projectiles/player_arrow.tscn")
	var arrow = arrow_scene.instantiate()
	
	# Setup arrow
	var damage = player.base_stats.base_damage if player.base_stats else 25.0
	arrow.setup(direction, player, damage)
	
	# Position
	var offset = Vector2(20 * direction.x, -10)
	arrow.global_position = player.global_position + offset
	
	# Add to scene
	player.get_tree().current_scene.add_child(arrow)
	print("[RangedAttackState] Arrow spawned manually")

func physics_update(_delta: float) -> void:
	# Có thể cho player di chuyển chậm khi bắn
	var move_speed = player.base_stats.calculated_move_speed * 0.3 if player.base_stats else 50.0
	
	# Slow movement allowed
	if player.is_on_floor():
		player.velocity.x = move_toward(player.velocity.x, 0, move_speed)
	else:
		player.velocity.y += player.gravity * _delta

func handle_input(controller: PlayerController) -> void:
	# Allow dash cancel
	if controller.get_dash_input() and player.can_dash():
		get_parent().change_state("DashState")
		return
	
	# Allow jump cancel on ground
	if player.is_on_floor() and controller.is_jump_pressed():
		player.velocity.y = player.jump_velocity
		get_parent().change_state("AirState")

func exit(_next_state: PlayerState) -> void:
	pass

func get_state_name() -> String:
	return "ranged_attack_state"
