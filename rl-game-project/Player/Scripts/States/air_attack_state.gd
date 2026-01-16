## AirAttackState - Air attack (chỉ dùng 1 lần cho mỗi lần nhảy)
## Plays "air_atk" animation
## Cannot be interrupted
## Player bị freeze trên không (velocity = 0)
## Reset flag khi chạm đất
## Supports ranged characters (spawns projectile instead of hitbox)
class_name AirAttackState
extends PlayerState

var attack_token: int = 0
var projectile_spawner: Node = null

func enter(_previous_state: PlayerState) -> void:
	# Find ProjectileSpawner for ranged characters
	if player.is_ranged_character:
		projectile_spawner = player.get_node_or_null("ProjectileSpawner")
	
	player._air_attack_used = true  # Mark đã dùng air attack
	attack_token = player._start_action(player.Action.AIR_ATTACK)
	player._combo_buffered = false
	player._combo_accepting_buffer = false
	player._combo_window_timer = 0.0
	
	# Allow hitbox/projectile to deal damage during this attack
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
	
	# Apply attack speed multiplier BEFORE playing animation
	if player.runtime_stats:
		var speed_mult = player.runtime_stats.get_attack_speed_multiplier()
		player.animation_player.speed_scale = speed_mult
	
	player.animation_player.play(anim_name)
	
	await player.animation_player.animation_finished
	
	# Reset animation speed
	if player.animation_player:
		player.animation_player.speed_scale = 1.0
	if player.animated_sprite:
		player.animated_sprite.speed_scale = 1.0
	
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

## Spawn projectile cho ranged attack
func _spawn_projectile() -> void:
	if not projectile_spawner:
		push_warning("[AirAttackState] ProjectileSpawner not found for ranged attack!")
		return
	
	# Gọi spawn_combo_arrow từ ProjectileSpawner
	if projectile_spawner.has_method("spawn_combo_arrow"):
		projectile_spawner.spawn_combo_arrow()
	elif projectile_spawner.has_method("spawn_facing_projectile"):
		projectile_spawner.spawn_facing_projectile()
	else:
		push_warning("[AirAttackState] ProjectileSpawner doesn't have spawn method!")
