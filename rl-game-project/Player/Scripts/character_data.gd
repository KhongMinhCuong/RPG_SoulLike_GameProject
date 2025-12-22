## CharacterData - Resource lưu thông tin nhân vật
## Mỗi nhân vật có stats khác nhau, sprite khác nhau
class_name CharacterData
extends Resource

# === CHARACTER INFO ===
@export var character_id: String = "warrior"  # ID duy nhất
@export var character_name: String = "Warrior"  # Tên hiển thị
@export_multiline var description: String = "Chiến binh mạnh mẽ với sức tấn công cao"

# === VISUAL ===
@export var character_portrait: Texture2D  # Hình đại diện trong menu chọn
@export var sprite_frames: SpriteFrames  # Animation sprites cho nhân vật

# === PLAYER SCENE ===
@export_file("*.tscn") var player_scene_path: String = ""  # Đường dẫn đến scene player riêng (prefab)
@export_file("*.tscn") var game_scene_path: String = "res://enemy/scenes/game.tscn"  # Scene game/map để chơi

# === STARTING STATS ===
@export_group("Starting Stats")
@export var starting_strength: int = 0
@export var starting_vitality: int = 0
@export var starting_dexterity: int = 0
@export var starting_movement_speed: int = 0
@export var starting_luck: int = 0

# === STAT POINTS ===
@export var starting_basic_points: int = 100  # Điểm ban đầu để phân phối
@export var starting_special_points: int = 3

# === ABILITIES (Optional - có thể làm sau) ===
@export var special_ability_name: String = ""
@export var special_ability_description: String = ""

# === GAMEPLAY MODIFIERS (Optional) ===
@export var damage_modifier: float = 1.0  # Multiplier cho damage
@export var health_modifier: float = 1.0  # Multiplier cho HP
@export var speed_modifier: float = 1.0  # Multiplier cho speed

func apply_to_stats(stats: PlayerStats) -> void:
	"""Áp dụng character data vào PlayerStats"""
	if not stats:
		return
	
	# Reset stats về 0
	stats.strength = starting_strength
	stats.vitality = starting_vitality
	stats.dexterity = starting_dexterity
	stats.movement_speed = starting_movement_speed
	stats.luck = starting_luck
	
	# Set điểm phân phối
	stats.basic_stat_points = starting_basic_points
	stats.special_upgrade_points = starting_special_points
	
	# Reset level và exp
	stats.current_level = 1
	stats.current_experience = 0
	
	# Recalculate tất cả
	stats._recalculate_all_stats()
	stats._update_exp_requirement()
	
	print("[CharacterData] Applied '%s' to stats" % character_name)

func get_summary() -> Dictionary:
	"""Trả về thông tin tóm tắt cho UI"""
	return {
		"id": character_id,
		"name": character_name,
		"description": description,
		"portrait": character_portrait,
		"starting_stats": {
			"str": starting_strength,
			"vit": starting_vitality,
			"dex": starting_dexterity,
			"mov": starting_movement_speed,
			"lck": starting_luck,
		},
		"points": {
			"basic": starting_basic_points,
			"special": starting_special_points,
		}
	}
