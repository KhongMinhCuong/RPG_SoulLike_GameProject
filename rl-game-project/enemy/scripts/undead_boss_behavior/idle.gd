@tool
extends ActionLeaf

@onready var animated_sprite: AnimatedSprite2D = $"../../../../AnimatedSprite2D"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if not actor:
		return FAILURE
	
	# Stop moving (both axes for flying boss)
	actor.velocity = Vector2.ZERO
	actor.move_and_slide()
	
	# Play idle animation
	if animated_sprite:
		animated_sprite.play("idle")
	
	return SUCCESS
