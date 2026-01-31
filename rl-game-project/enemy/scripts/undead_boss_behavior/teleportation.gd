@tool
extends ActionLeaf

var teleport_points: Array[Node2D]

func tick(actor: Node, blackboard: Blackboard) -> int:
	teleport_points = actor.teleport_points
	if teleport_points.is_empty():
		print("[Teleportation] actor.teleport_points empty for actor:", actor)
		return FAILURE

    var point = teleport_points.pick_random()
    print("[Teleportation] picked point=", point, " global_position=", point.global_position)
    blackboard.set_value("teleport_pos", point.global_position)
    var stored = blackboard.get_value("teleport_pos")
    print("[Teleportation] blackboard teleport_pos set to: ", stored)
    return SUCCESS