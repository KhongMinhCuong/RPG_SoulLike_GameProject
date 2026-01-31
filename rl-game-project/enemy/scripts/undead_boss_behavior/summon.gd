@tool
extends ActionLeaf

@export var minion_scene: PackedScene
@onready var summon_points: Node2D = $"../../../../SummonPoints"
@onready var animation_player: AnimationPlayer = $"../../../../AnimationPlayer"

var started := false

func tick(actor: Node, _blackboard: Blackboard) -> int:
	if not minion_scene or not summon_points:
		return FAILURE

	var points := summon_points.get_children()
	if points.is_empty():
		return FAILURE

	# Start animation on first tick
	if not started:
		started = true
		animation_player.play("summon")
		return RUNNING

	# Wait for animation to finish
	if animation_player.is_playing():
		return RUNNING

	# Animation done, now spawn minions
	for spawn_point in points:
		var p := spawn_point as Node2D
		if p == null:
			continue

		var m = minion_scene.instantiate()
		m.global_position = p.global_position
		get_tree().current_scene.add_child(m)

	actor.summon_cd_left = actor.summon_cooldown
	started = false
	return SUCCESS
