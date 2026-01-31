@tool
extends ActionLeaf

@onready var animated_sprite: AnimatedSprite2D = $"../../../../AnimatedSprite2D"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if not actor or not actor.player:
		return FAILURE
	
	# Face player
	actor.face_target(actor.player)
	
	# Calculate 2D direction vector towards a point slightly above the player
	# so the boss will 'stand' over the player a bit.
	var target_pos = actor.player.global_position + Vector2(0, -(actor.hover_offset if "hover_offset" in actor else 24.0))
	var vec = target_pos - actor.global_position
	if vec.length() > 0.01:
		var vel = vec.normalized() * actor.move_speed
		actor.velocity = vel
	else:
		actor.velocity = Vector2.ZERO

	actor.move_and_slide()
	
	# Play walk animation
	if animated_sprite:
		animated_sprite.play("walk")
	
	return SUCCESS
