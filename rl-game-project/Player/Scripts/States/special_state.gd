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
	
	player.play_animation(&"sp_atk", true)
	
	await player.animated_sprite.animation_finished
	
	if special_token != player._action_token:
		return  # Bị interrupt
	
	player._end_action(special_token)
	
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
