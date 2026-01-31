@tool
extends ActionLeaf

var teleport_points: Array[Node2D]

func tick(actor: Node, blackboard: Blackboard) -> int:
	teleport_points = actor.teleport_points
	if teleport_points.is_empty():
		return FAILURE

	var point = teleport_points.pick_random()
	blackboard.set("teleport_pos", point.global_position)
	return SUCCESS
