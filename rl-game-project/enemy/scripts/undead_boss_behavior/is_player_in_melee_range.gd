@tool
extends ConditionLeaf

func tick(actor: Node, blackboard: Blackboard) -> int:
	if not actor or not actor.player:
		return FAILURE
	
	var distance = actor.global_position.distance_to(actor.player.global_position)
	if distance <= actor.melee_range:
		return SUCCESS
	return FAILURE
