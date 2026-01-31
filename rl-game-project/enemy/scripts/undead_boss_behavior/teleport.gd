@tool
extends ActionLeaf

@onready var animation_player: AnimationPlayer = $"../../../../AnimationPlayer"
@onready var hurtbox: Hurtbox = $"../../../../Hurtbox"

var started := false

func tick(actor: Node, blackboard: Blackboard) -> int:
	var pos = blackboard.get_value("teleport_pos")
	if pos == null:
		print("[Teleport] teleport_pos is null on blackboard. blackboard=", blackboard)
		return FAILURE	# Start teleport animation first (if not started). Keep animation running
	# before performing the actual teleport.
	if not started:
		started = true
		hurtbox.disable()
		animation_player.play("teleport")
		# keep running while animation plays
		return RUNNING

	# when animation finished, perform teleport
	if not animation_player.is_playing():
		# perform teleport move
		actor.visible = false
		actor.set_physics_process(false)
		actor.global_position = pos
		actor.visible = true
		hurtbox.enable()
		actor.set_physics_process(true)

		# reset started so leaf can be re-used if needed
		started = false
		return SUCCESS

	return RUNNING
