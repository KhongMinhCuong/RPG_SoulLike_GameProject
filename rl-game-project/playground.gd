## Playground Scene - Main game scene để test và chơi
extends Node2D

@export var player_spawn_position: Vector2 = Vector2(100, 100)  # Vị trí spawn player

@onready var touch_controls = $Control/TouchControls  # Reference đến touch controls

func _ready() -> void:
	print("[Playground] Scene loaded")
	
	# Chờ 1 frame để đảm bảo tất cả node đã sẵn sàng
	await get_tree().process_frame
	
	# Spawn player theo character đã chọn
	_spawn_player()

func _spawn_player() -> void:
	"""Spawn player instance theo character đã chọn từ GameManager"""
	
	# Kiểm tra GameManager
	if not has_node("/root/GameManager"):
		push_error("[Playground] GameManager not found!")
		return
	
	var game_manager = get_node("/root/GameManager")
	
	# Kiểm tra đã chọn character chưa
	if not game_manager.has_selected_character():
		push_error("[Playground] No character selected!")
		return
	
	var character_data = game_manager.get_selected_character()
	print("[Playground] Spawning player for character: ", character_data.character_name)
	
	# Lấy player scene path
	var player_scene_path = character_data.player_scene_path
	if player_scene_path.is_empty():
		push_error("[Playground] Character has no player scene path!")
		return
	
	# Load player scene
	var player_scene = load(player_scene_path)
	if not player_scene:
		push_error("[Playground] Failed to load player scene: ", player_scene_path)
		return
	
	# Lưu lại vị trí và touch controls của player cũ
	var old_player = get_node_or_null("Player")
	var old_position = player_spawn_position
	var old_touch_controls_path = NodePath()
	
	if old_player:
		print("[Playground] Found old player, replacing...")
		old_position = old_player.position
		
		# Lưu touch_controls reference
		if old_player.has("touch_controls") and old_player.touch_controls:
			old_touch_controls_path = old_player.get_path_to(old_player.touch_controls)
		
		# Xóa player cũ
		old_player.queue_free()
	
	# Instance player mới
	var player_instance = player_scene.instantiate()
	player_instance.name = "Player"
	player_instance.position = old_position
	
	# Gán touch controls reference
	if player_instance.has("touch_controls") and touch_controls:
		player_instance.touch_controls = touch_controls
		print("[Playground] Touch controls assigned to player")
	
	# Add vào scene
	add_child(player_instance)
	print("[Playground] Player spawned at ", player_instance.position)
	print("[Playground] Player visible: ", player_instance.visible)
	
	# Debug: List children
	await get_tree().process_frame
	print("[Playground] Total children in scene: ", get_child_count())
	for child in get_children():
		if child is Node2D:
			print("  - ", child.name, " at position ", child.position, " visible: ", child.visible)
