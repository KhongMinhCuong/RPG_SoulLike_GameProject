@tool
extends ActionLeaf


func tick(actor: Node, blackboard: Blackboard) -> int:
	actor.visible = false
	actor.set_physics_process(false)
	
	var pos = blackboard.get("teleport_pos")
	if pos == null:
		return FAILURE

	actor.global_position = pos
	actor.visible = true
	actor.set_physics_process(true)
	
	return SUCCESS
