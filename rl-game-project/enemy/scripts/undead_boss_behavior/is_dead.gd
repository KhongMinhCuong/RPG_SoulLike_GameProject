@tool
extends ConditionLeaf


func tick(actor: Node, _blackboard: Blackboard) -> int:
	if not actor:
		print("Actor not assigned")
		return FAILURE
	
	var actor_health: float = float(actor.health)
	if actor_health <= 0:
		return SUCCESS
	else:
		return FAILURE
