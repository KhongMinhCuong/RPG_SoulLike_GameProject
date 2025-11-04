## DeadState - Player đã chết
## Plays "death" animation
## Cannot transition ra khỏi state này
## Velocity = 0
class_name DeadState
extends PlayerState

func enter(_previous_state: PlayerState) -> void:
	player._interrupt_current_action()
	player.velocity = Vector2.ZERO
	player._action_token += 1
	player.current_action = player.Action.DEAD
	player.died.emit()
	
	player.play_animation(&"death", true)
	
	await player.animated_sprite.animation_finished
	
	# Stay in dead state - không chuyển sang state khác

func physics_update(_delta: float) -> void:
	# Không có movement khi chết
	player.velocity = Vector2.ZERO

func handle_input(_controller: PlayerController) -> void:
	# Không thể làm gì khi chết
	pass
