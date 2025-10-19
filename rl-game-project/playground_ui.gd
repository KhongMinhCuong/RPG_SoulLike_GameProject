extends CanvasLayer

func _on_damage_button_pressed() -> void:
	# damage the player
	var player = get_node("../Player")
	if player:
		player.take_damage(10)

func _on_reset_button_pressed() -> void:
	# reset scene
	var tree = get_tree()
	tree.reload_current_scene()
