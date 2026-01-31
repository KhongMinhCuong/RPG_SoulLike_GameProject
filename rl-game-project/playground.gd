## Playground Scene - Main game scene để test và chơi
extends Node2D

const GameConstants = preload("res://Scripts/game_constants.gd")

@export var player_spawn_position: Vector2 = Vector2(100, 100)  # Vị trí spawn player

@onready var touch_controls = $Control/TouchControls  # Reference đến touch controls

var total_enemies: int = 0
var defeated_enemies: int = 0

func _ready() -> void:
	print("[Playground] Scene loaded")
	
	# Chờ 1 frame để đảm bảo tất cả node đã sẵn sàng
	await get_tree().process_frame
	
	# Spawn player theo character đã chọn
	_spawn_player()
	
	# Đếm số lượng enemy ban đầu và kết nối signal
	_count_initial_enemies()

func _count_initial_enemies() -> void:
	"""Đếm số enemy ban đầu và kết nối signal tree_exited"""
	var enemies = get_tree().get_nodes_in_group("Enemy")
	total_enemies = enemies.size()
	defeated_enemies = 0
	
	print("[Playground] Found ", total_enemies, " enemies")
	
	for enemy in enemies:
		# Kết nối signal khi enemy bị xóa khỏi scene tree (khi chết)
		enemy.tree_exited.connect(_on_enemy_defeated)
	
	# Nếu không có enemy nào, chuyển ngay sang boss level
	if total_enemies == 0:
		_goto_boss_level()

func _on_enemy_defeated() -> void:
	"""Khi một enemy bị tiêu diệt"""
	defeated_enemies += 1
	print("[Playground] Enemy defeated! ", defeated_enemies, "/", total_enemies)
	
	# Nếu tất cả enemy đã bị tiêu diệt, chuyển sang boss level
	if defeated_enemies >= total_enemies:
		_goto_boss_level()

func _goto_boss_level() -> void:
	"""Chuyển sang màn boss"""
	print("[Playground] All enemies defeated! Going to boss level...")
	
	# Chuyển scene sang boss level
	var result = get_tree().change_scene_to_file("res://BossLevels/scene/FirstBossLevel.tscn")
	if result != OK:
		push_error("[Playground] Failed to change to boss level! Error code: ", result)

func _spawn_player() -> void:
	"""Spawn player instance theo character đã chọn từ GameManager"""
	
	# Kiểm tra GameManager
	if not has_node(GameConstants.GAME_MANAGER_PATH):
		push_error("[Playground] GameManager not found!")
		return
	
	var game_manager = get_node(GameConstants.GAME_MANAGER_PATH)
	
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
	
	# Instance player mới trước
	var player_instance = player_scene.instantiate()
	player_instance.name = "Player"
	
	if old_player:
		print("[Playground] Found old player, replacing...")
		old_position = old_player.position
		
		# Remove player cũ khỏi scene tree trước
		remove_child(old_player)
		# Xóa player cũ sau khi đã remove khỏi tree
		old_player.queue_free()
	
	# Set vị trí cho player mới
	player_instance.position = old_position
	
	# Gán touch controls reference
	if "touch_controls" in player_instance and touch_controls:
		player_instance.touch_controls = touch_controls
		print("[Playground] Touch controls assigned to player")
	
	# Add player mới vào scene (enemy sẽ tìm lại qua group "Player")
	add_child(player_instance)
	
	# Đợi 1 frame để player được add vào scene tree đầy đủ
	await get_tree().process_frame
	
	# Update tất cả enemies để họ biết về player mới
	_update_enemies_player_reference(player_instance)
	
	print("[Playground] Player spawned at ", player_instance.position)
	print("[Playground] Player visible: ", player_instance.visible)
	
	# Debug: List children
	await get_tree().process_frame
	print("[Playground] Total children in scene: ", get_child_count())
	for child in get_children():
		if child is Node2D:
			print("  - ", child.name, " at position ", child.position, " visible: ", child.visible)

func _update_enemies_player_reference(new_player: CharacterBody2D) -> void:
	"""Update tất cả enemies để họ biết về player mới"""
	# Tìm tất cả enemies trong scene (giả sử enemies là CharacterBody2D và có property 'player')
	for node in get_tree().get_nodes_in_group("Enemy"):
		if "player" in node:
			node.player = new_player
			print("[Playground] Updated enemy ", node.name, " player reference")
	
	# Fallback: tìm theo type nếu không có group
	var all_enemies = _find_all_enemies(self)
	for enemy in all_enemies:
		if "player" in enemy:
			enemy.player = new_player
			print("[Playground] Updated enemy ", enemy.name, " player reference (by type)")

func _find_all_enemies(node: Node) -> Array:
	"""Đệ quy tìm tất cả enemy nodes (fallback nếu không có group)"""
	var enemies: Array = []
	
	# Check nếu node này là enemy (có property 'player' và không phải Player)
	if "player" in node and node != get_node_or_null("Player"):
		enemies.append(node)
	
	# Đệ quy qua các children
	for child in node.get_children():
		enemies.append_array(_find_all_enemies(child))
	
	return enemies
