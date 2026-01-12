## ArcherAirAttackState - Air attack cho Archer
## Spawn arrow khi attack trên không
class_name ArcherAirAttackState
extends PlayerState

var attack_token: int = 0
var projectile_spawner: Node = null

func enter(_previous_state: PlayerState) -> void:
	if not player.can_air_attack():
		# Không thể air attack, return về AirState
		get_parent().change_state("AirState")
		return
	
	# Find ProjectileSpawner
	projectile_spawner = player.get_node_or_null("ProjectileSpawner")
	
	player._air_attack_used = true
	attack_token = player._start_action(player.Action.AIR_ATTACK)
	
	_execute_air_attack()

func _execute_air_attack() -> void:
	var anim_name = player.AIR_ATTACK["anim"]
	
	# Play animation
	if player.animation_player and player.animation_player.has_animation(anim_name):
		player.animation_player.play(anim_name)
	elif player.animated_sprite:
		player.play_animation(anim_name, true)
	
	# Wait 30% of animation then spawn arrow
	var anim_length = player._get_animation_length(anim_name)
	if anim_length > 0:
		await player.get_tree().create_timer(anim_length * 0.3).timeout
	
	if attack_token != player._action_token:
		return
	
	# Spawn arrow
	_spawn_arrow()
	
	# Wait for animation finish
	if player.animation_player:
		await player.animation_player.animation_finished
	else:
		await player.animated_sprite.animation_finished
	
	if attack_token != player._action_token:
		return
	
	player._end_action(attack_token)
	
	# Return to air state
	get_parent().change_state("AirState")

func _spawn_arrow() -> void:
	if not projectile_spawner:
		push_warning("[ArcherAirAttackState] ProjectileSpawner not found!")
		return
	
	projectile_spawner.spawn_combo_arrow()

func physics_update(delta: float) -> void:
	# Apply gravity
	player.velocity.y += player.gravity * delta
	
	# Slow horizontal movement
	player.velocity.x = move_toward(player.velocity.x, 0, 50 * delta)

func handle_input(controller: PlayerController) -> void:
	# Dash cancel
	if controller.is_dash_pressed() and player.can_dash():
		get_parent().change_state("DashState")

func get_state_name() -> String:
	return "archer_air_attack_state"
