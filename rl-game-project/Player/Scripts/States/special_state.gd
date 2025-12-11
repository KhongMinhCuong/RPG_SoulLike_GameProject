## SpecialState - Special attack action
## Plays "sp_atk" animation
## Cannot be interrupted
## Player bị freeze hoàn toàn (velocity = 0)
class_name SpecialState
extends PlayerState

var special_token: int = 0

func enter(_previous_state: PlayerState) -> void:
	special_token = player._start_action(player.Action.SPECIAL)
	
	# Freeze hoàn toàn
	player.velocity = Vector2.ZERO
	
	# Disable hurtbox if invincible during special attack
	if player.invincible_during_special and player.hurtbox:
		player.hurtbox.monitoring = false
		player.hurtbox.monitorable = false
	
	player.play_animation(&"sp_atk", true)
	
	# Enable special attack hitbox (shape 4)
	if player.hitbox:
		player.hitbox.enable_shape(4)
	
	await player.animated_sprite.animation_finished
	
	if special_token != player._action_token:
		return  # Bị interrupt
	
	player._end_action(special_token)
	
	# Disable hitbox
	if player.hitbox:
		player.hitbox.disable()
	
	# Re-enable hurtbox if it was disabled
	if player.invincible_during_special and player.hurtbox:
		player.hurtbox.monitoring = true
		player.hurtbox.monitorable = true
	
	# Return về state phù hợp
	if player.is_on_floor():
		get_parent().change_state("GroundedState")
	else:
		get_parent().change_state("AirState")

func physics_update(_delta: float) -> void:
	# Frozen trong lúc special attack
	player.velocity = Vector2.ZERO

func handle_input(_controller: PlayerController) -> void:
	# Không thể làm gì trong lúc special
	pass
