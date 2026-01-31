@tool
extends ConditionLeaf


func tick(actor: Node, _blackboard: Blackboard) -> int:
	if actor.summon_cd_left > 0:
		return FAILURE

	return SUCCESS
