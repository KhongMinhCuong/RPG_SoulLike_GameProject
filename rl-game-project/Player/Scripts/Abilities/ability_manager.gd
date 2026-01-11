## AbilityManager - Quản lý abilities và passives cho Player
## Load, update, và trigger abilities dựa trên input
## Node này phải được thêm vào Player scene
class_name AbilityManager
extends Node

# === PRELOADS for class types ===
const AbilityBaseScript = preload("res://Player/Scripts/Abilities/ability_base.gd")
const PassiveBaseScript = preload("res://Player/Scripts/Abilities/passive_base.gd")

# === REFERENCES ===
@export var player_path: NodePath = ".."
var player: Node = null

# === ABILITY STORAGE ===
var abilities: Dictionary = {}  # String -> AbilityBase
var passives: Array = []  # Array of PassiveBase

# === INPUT MAPPING ===
var ability_inputs: Dictionary = {}  # String (input_action) -> AbilityBase

# === SIGNALS ===
signal ability_used(ability_name: String)
signal passive_triggered(passive_name: String)

func _ready() -> void:
	player = get_node_or_null(player_path)
	if not player:
		push_error("[AbilityManager] Player not found at path: %s" % player_path)
		return
	
	# Load abilities từ character data (nếu có)
	_load_abilities_from_character()

func _load_abilities_from_character() -> void:
	"""Load abilities từ CharacterData của player"""
	if not player or not player.has_method("get_character_data"):
		# Try alternative method
		if player.has_node("/root/GameManager"):
			var gm = player.get_node("/root/GameManager")
			if gm.has_method("get_selected_character"):
				var char_data = gm.get_selected_character()
				if char_data:
					_load_from_character_data(char_data)
					return
	
	# Direct character data access
	if player and "character_data" in player and player.character_data:
		_load_from_character_data(player.character_data)

func _load_from_character_data(char_data: Resource) -> void:
	"""Load abilities và passives từ CharacterData resource"""
	# Load Active Abilities
	if "ability_script_paths" in char_data and "ability_input_actions" in char_data:
		var paths: Array = char_data.ability_script_paths
		var inputs: Array = char_data.ability_input_actions
		
		for i in range(paths.size()):
			var path: String = paths[i] if i < paths.size() else ""
			var input_action: String = inputs[i] if i < inputs.size() else ""
			
			if path != "" and ResourceLoader.exists(path):
				var script = load(path)
				if script:
					var ability = script.new()
					if ability is AbilityBaseScript:
						add_ability(ability, input_action)
						print("[AbilityManager] Loaded ability: %s" % ability.ability_name)
					else:
						push_warning("[AbilityManager] Script is not AbilityBase: %s" % path)
			elif path != "":
				push_warning("[AbilityManager] Ability script not found: %s" % path)
	
	# Load Passives
	if "passive_script_paths" in char_data:
		var passive_paths: Array = char_data.passive_script_paths
		
		for path in passive_paths:
			if path != "" and ResourceLoader.exists(path):
				var script = load(path)
				if script:
					var passive = script.new()
					if passive is PassiveBaseScript:
						add_passive(passive)
						print("[AbilityManager] Loaded passive: %s" % passive.passive_name)
					else:
						push_warning("[AbilityManager] Script is not PassiveBase: %s" % path)
			elif path != "":
				push_warning("[AbilityManager] Passive script not found: %s" % path)

## Add an ability manually
func add_ability(ability: RefCounted, input_action: String = "") -> void:
	ability.initialize(player)
	abilities[ability.ability_name] = ability
	
	if input_action != "":
		ability_inputs[input_action] = ability
	
	# Connect signals
	ability.ability_activated.connect(_on_ability_activated)

## Add a passive manually
func add_passive(passive: RefCounted) -> void:
	passive.initialize(player)
	passive.apply_stat_modifiers()
	passives.append(passive)
	
	# Connect signals
	passive.passive_triggered.connect(_on_passive_triggered)

## Remove an ability
func remove_ability(ability_name: String) -> void:
	if ability_name in abilities:
		var ability = abilities[ability_name]
		ability.cleanup()
		
		# Remove from input mapping
		for input_action in ability_inputs.keys():
			if ability_inputs[input_action] == ability:
				ability_inputs.erase(input_action)
		
		abilities.erase(ability_name)

## Remove a passive
func remove_passive(passive_name: String) -> void:
	for i in range(passives.size()):
		if passives[i].passive_name == passive_name:
			passives[i].cleanup()
			passives.remove_at(i)
			return

func _process(delta: float) -> void:
	# Update ability cooldowns
	for ability in abilities.values():
		ability.update(delta)
	
	# Update passives
	for passive in passives:
		passive.update(delta)

func _unhandled_input(event: InputEvent) -> void:
	# Check ability inputs
	for input_action in ability_inputs.keys():
		if event.is_action_pressed(input_action):
			var ability = ability_inputs[input_action]
			if ability.can_use():
				ability.activate()
				ability_used.emit(ability.ability_name)
				get_viewport().set_input_as_handled()
				return

## Try to use ability by name
func use_ability(ability_name: String) -> bool:
	if ability_name in abilities:
		var ability = abilities[ability_name]
		if ability.can_use():
			ability.activate()
			ability_used.emit(ability_name)
			return true
	return false

## Try to use ability by input action
func use_ability_by_input(input_action: String) -> bool:
	if input_action in ability_inputs:
		var ability = ability_inputs[input_action]
		if ability.can_use():
			ability.activate()
			ability_used.emit(ability.ability_name)
			return true
	return false

## Get ability info
func get_ability_info(ability_name: String) -> Dictionary:
	if ability_name in abilities:
		return abilities[ability_name].get_info()
	return {}

## Get all abilities info
func get_all_abilities_info() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for ability in abilities.values():
		result.append(ability.get_info())
	return result

## Get all passives info
func get_all_passives_info() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for passive in passives:
		result.append(passive.get_info())
	return result

## Notify passives of damage taken (return modified damage)
func notify_damage_taken(damage: float) -> float:
	var modified_damage = damage
	for passive in passives:
		modified_damage = passive.on_damage_taken(modified_damage)
	return modified_damage

## Notify passives of damage dealt (return modified damage)
func notify_damage_dealt(damage: float, target: Node) -> float:
	var modified_damage = damage
	for passive in passives:
		modified_damage = passive.on_damage_dealt(modified_damage, target)
	return modified_damage

## Notify passives of attack
func notify_attack() -> void:
	for passive in passives:
		passive.on_attack()

## Notify passives of kill
func notify_kill(enemy: Node) -> void:
	for passive in passives:
		passive.on_kill(enemy)

## Notify passives of dash
func notify_dash() -> void:
	for passive in passives:
		passive.on_dash()

## Notify passives of successful parry
func notify_parry_success() -> void:
	for passive in passives:
		passive.on_parry_success()

## Notify passives of health change
func notify_health_changed(current: float, max_health: float) -> void:
	for passive in passives:
		passive.on_health_changed(current, max_health)

func _on_ability_activated(ability_name: String) -> void:
	print("[AbilityManager] Ability activated: %s" % ability_name)

func _on_passive_triggered(passive_name: String) -> void:
	passive_triggered.emit(passive_name)
	print("[AbilityManager] Passive triggered: %s" % passive_name)

## Reset all abilities and passives
func reset_all() -> void:
	for ability in abilities.values():
		ability.reset()
	for passive in passives:
		passive.reset()

## Cleanup all
func cleanup() -> void:
	for ability in abilities.values():
		ability.cleanup()
	abilities.clear()
	ability_inputs.clear()
	
	for passive in passives:
		passive.cleanup()
	passives.clear()
