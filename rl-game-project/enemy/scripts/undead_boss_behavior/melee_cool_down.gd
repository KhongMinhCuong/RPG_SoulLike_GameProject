@tool
extends ActionLeaf

var timer := 0.0

func enter(actor: Node, blackboard: Blackboard) -> void:
	if actor:
		timer = actor.attack_cooldown

func tick(actor: Node, blackboard: Blackboard) -> int:
	if actor:
		timer -= get_process_delta_time()
	
	if timer <= 0.0:
		timer = 0.0
		return SUCCESS
	
	return RUNNING
