## SpecialState - Special attack action
## Plays "sp_atk" animation
## Cannot be interrupted
## Player bị freeze hoàn toàn (velocity = 0)
class_name SpecialState
extends PlayerState

var special_token: int = 0

func enter(_previous_state: PlayerState) -> void:
	special_token = player._start_action(player.Action.SPECIAL)
	
	# Allow hitbox to deal damage during this attack
	player._allow_hitbox_activation = true
	
	# Freeze hoàn toàn
	player.velocity = Vector2.ZERO
	
	# Disable hurtbox if invincible during special attack
	if player.invincible_during_special and player.hurtbox:
		player.hurtbox.monitoring = false
		player.hurtbox.monitorable = false
	
	# Play animation via AnimationPlayer (controls hitbox via method tracks)
	var anim_name = &"sp_atk"
	
	if not player.animation_player or not player.animation_player.has_animation(anim_name):
		push_error("AnimationPlayer animation '%s' not found! Create it with method tracks." % anim_name)
		# Cleanup before exiting
		player._allow_hitbox_activation = false
		if player.invincible_during_special and player.hurtbox:
			player.hurtbox.monitoring = true
			player.hurtbox.monitorable = true
		player._end_action(special_token)
		# Immediately transition back
		if player.is_on_floor():
			get_parent().change_state("GroundedState")
		else:
			get_parent().change_state("AirState")
		return
	
	player.animation_player.play(anim_name)
	await player.animation_player.animation_finished
	
	if special_token != player._action_token:
		return  # Bị interrupt
	
	player._end_action(special_token)
	
	# Prevent further damage from this attack
	player._allow_hitbox_activation = false
	
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
