@tool
extends ActionLeaf

@onready var hurtbox: Hurtbox = $"../../../../Hurtbox"
@onready var animation_player: AnimationPlayer = $"../../../../AnimationPlayer"

var started := false

func tick(actor: Node, _blackboard: Blackboard) -> int:
	if not started:
		started = true
		hurtbox.disable()
		animation_player.play("death")
		return RUNNING

	if not animation_player.is_playing():
		actor.queue_free()
		return SUCCESS
	
	return RUNNING
