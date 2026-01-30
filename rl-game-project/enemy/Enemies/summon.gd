@tool
extends ActionLeaf

@export var minion_scene: PackedScene
@onready var summon_points: Node2D = $"../../../../SummonPoints"

func tick(actor: Node, _blackboard: Blackboard) -> int:
	if not minion_scene or not summon_points:
		return FAILURE

	var points := summon_points.get_children()
	if points.is_empty():
		return FAILURE

	for spawn_point in points:
		var p := spawn_point as Node2D
		if p == null:
			continue

		var m = minion_scene.instantiate()
		m.global_position = p.global_position
		get_tree().current_scene.add_child(m)

	actor.summon_cd_left = actor.summon_cooldown
	return SUCCESS
