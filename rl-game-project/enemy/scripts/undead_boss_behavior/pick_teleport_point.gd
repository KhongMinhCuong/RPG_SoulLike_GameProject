@tool
extends ActionLeaf

var teleport_points: Array[Node2D]

func tick(actor: Node, blackboard: Blackboard) -> int:
	teleport_points = actor.teleport_points
	if teleport_points.is_empty():
		return FAILURE

	var point = teleport_points.pick_random()
	blackboard.set_value("teleport_pos", point.global_position)

	var stored = blackboard.get_value("teleport_pos")
	return SUCCESS
