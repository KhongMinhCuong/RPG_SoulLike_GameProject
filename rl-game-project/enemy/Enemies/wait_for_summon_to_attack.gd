@tool
extends ActionLeaf

@export var wait_time := 2.0
var timer := 0.0

func enter(actor, blackboard):
	timer = wait_time

func tick(actor, blackboard):
	timer -= get_process_delta_time()
	return SUCCESS if timer <= 0 else RUNNING
