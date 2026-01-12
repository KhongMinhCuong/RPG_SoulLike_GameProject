## Character Selection Screen Script
extends Control

@export var available_characters: Array[Resource] = []  # Array of CharacterData

# UI References
@onready var character_list = $VBox/MainContent/CharacterList
@onready var detail_panel = $VBox/MainContent/DetailPanel
@onready var portrait = $VBox/MainContent/DetailPanel/VBox/PortraitRect
@onready var name_label = $VBox/MainContent/DetailPanel/VBox/NameLabel
@onready var description_label = $VBox/MainContent/DetailPanel/VBox/DescriptionLabel
@onready var stats_label = $VBox/MainContent/DetailPanel/VBox/StatsLabel
@onready var start_button = $VBox/StartButton

var selected_character: Resource = null

func _ready() -> void:
	_populate_character_list()
	start_button.disabled = true
	start_button.pressed.connect(_on_start_button_pressed)

func _populate_character_list() -> void:
	"""Tạo button cho mỗi nhân vật"""
	for child in character_list.get_children():
		child.queue_free()
	
	for character in available_characters:
		var button = Button.new()
		button.text = character.character_name
		button.custom_minimum_size = Vector2(0, 25)
		button.pressed.connect(_on_character_selected.bind(character))
		character_list.add_child(button)

func _on_character_selected(character: Resource) -> void:
	"""Khi chọn nhân vật"""
	selected_character = character
	_update_detail_panel(character)
	start_button.disabled = false

func _update_detail_panel(character: Resource) -> void:
	"""Cập nhật thông tin nhân vật"""
	# Hiện detail panel
	detail_panel.visible = true
	
	if character.character_portrait:
		portrait.texture = character.character_portrait
	else:
		portrait.texture = null
	
	name_label.text = character.character_name
	description_label.text = character.description
	
	# Hiển thị starting stats
	var stats_text = "Starting Stats:\n"
	stats_text += "STR: %d | VIT: %d\n" % [character.starting_strength, character.starting_vitality]
	stats_text += "DEX: %d | MOV: %d | LCK: %d\n" % [character.starting_dexterity, character.starting_movement_speed, character.starting_luck]
	stats_text += "\nStat Points: %d\nSpecial Points: %d" % [character.starting_basic_points, character.starting_special_points]
	stats_label.text = stats_text

func _on_start_button_pressed() -> void:
	"""Bắt đầu game với nhân vật đã chọn"""
	print("[CharacterSelection] Start button pressed")
	
	if not selected_character:
		print("[CharacterSelection] ERROR: No character selected!")
		return
	
	print("[CharacterSelection] Selected character: ", selected_character.character_name)
	print("[CharacterSelection] Player scene path: ", selected_character.player_scene_path)
	
	# Truy cập GameManager qua Autoload (Godot 4.x)
	if not has_node("/root/GameManager"):
		push_error("[CharacterSelection] GameManager not found in Autoload!")
		return
	
	var game_manager = get_node("/root/GameManager")
	print("[CharacterSelection] GameManager found, calling select_character and goto_game")
	game_manager.select_character(selected_character)
	game_manager.goto_game()
