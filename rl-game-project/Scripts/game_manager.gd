## GameManager - Singleton quản lý trạng thái game toàn cục
## Chứa thông tin nhân vật được chọn, save/load game
extends Node

signal character_selected(character: Resource)
signal game_state_changed(new_state: String)

# === SELECTED CHARACTER ===
var selected_character: Resource = null  # CharacterData đã chọn
var current_player_node: Node = null  # Reference đến player instance hiện tại

# === SAVE DATA ===
var save_file_path: String = "user://savegame.dat"
var current_save_data: Dictionary = {}

func _ready() -> void:
	print("[GameManager] Initialized")

# === CHARACTER SELECTION ===
func select_character(character: Resource) -> void:
	"""Chọn nhân vật để chơi"""
	selected_character = character
	print("[GameManager] Character selected: ", character.character_name if character else "None")
	character_selected.emit(character)

func has_selected_character() -> bool:
	"""Kiểm tra đã chọn nhân vật chưa"""
	return selected_character != null

func get_selected_character() -> Resource:
	"""Lấy nhân vật đã chọn"""
	return selected_character

func get_player_scene_path() -> String:
	"""Lấy đường dẫn đến scene player của nhân vật đã chọn"""
	if not selected_character:
		return ""
	return selected_character.player_scene_path

# === SCENE MANAGEMENT ===
func goto_character_selection() -> void:
	"""Chuyển về màn hình chọn nhân vật"""
	get_tree().change_scene_to_file("res://Scenes/character_selection.tscn")

func goto_game() -> void:
	"""Bắt đầu game với nhân vật đã chọn"""
	print("[GameManager] goto_game() called")
	
	if not has_selected_character():
		push_error("[GameManager] No character selected!")
		return
	
	# Lấy game scene path từ character data
	var game_scene_path = selected_character.game_scene_path
	if game_scene_path.is_empty():
		game_scene_path = "res://enemy/scenes/game.tscn"  # Fallback to default
	
	print("[GameManager] Game scene path: ", game_scene_path)
	
	# Kiểm tra file có tồn tại không
	if not ResourceLoader.exists(game_scene_path):
		push_error("[GameManager] Scene file does not exist: ", game_scene_path)
		return
	
	# Chuyển scene đến game scene
	print("[GameManager] Changing scene to: ", game_scene_path)
	var result = get_tree().change_scene_to_file(game_scene_path)
	if result != OK:
		push_error("[GameManager] Failed to change scene! Error code: ", result)

# === SAVE/LOAD ===
func save_game() -> void:
	"""Lưu game"""
	if not has_selected_character():
		return
	
	current_save_data = {
		"character_id": selected_character.character_id,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_var(current_save_data)
		file.close()
		print("[GameManager] Game saved")

func load_game() -> bool:
	"""Load game - returns true nếu load thành công"""
	if not FileAccess.file_exists(save_file_path):
		return false
	
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if not file:
		return false
	
	current_save_data = file.get_var()
	file.close()
	
	print("[GameManager] Game loaded")
	return true

func has_save_data() -> bool:
	"""Kiểm tra có save game không"""
	return FileAccess.file_exists(save_file_path)
