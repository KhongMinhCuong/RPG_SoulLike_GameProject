extends CanvasLayer

func _on_damage_button_pressed() -> void:
	# damage the player
	var player = get_node("../Player")
	var monster = get_node("../Skeleton")
	if monster:
		monster.take_damage(20, true)

func _on_reset_button_pressed() -> void:
	# reset scene
	var tree = get_tree()
	tree.reload_current_scene()
