## AbilityBase - Base class cho tất cả Active Abilities
## Mỗi nhân vật có 1 hoặc nhiều ability riêng
## Ability được trigger bởi input action (ability_1, ability_2, etc.)
class_name AbilityBase
extends RefCounted

# === ABILITY INFO ===
var ability_name: String = "Base Ability"
var description: String = "Ability description"
var icon: Texture2D = null

# === COOLDOWN ===
var cooldown: float = 5.0  # Cooldown time in seconds
var current_cooldown: float = 0.0  # Current remaining cooldown

# === COST ===
var mana_cost: float = 0.0  # Mana/Energy cost (if applicable)
var health_cost: float = 0.0  # HP cost (if applicable)

# === REFERENCES ===
var player: Node = null  # Reference to player

# === SIGNALS ===
signal ability_activated(ability_name: String)
signal ability_cooldown_started(ability_name: String, duration: float)
signal ability_ready(ability_name: String)

## Initialize ability with player reference
func initialize(player_ref: Node) -> void:
	player = player_ref
	current_cooldown = 0.0
	_on_initialize()

## Virtual method - override in subclasses for custom initialization
func _on_initialize() -> void:
	pass

## Check if ability can be used
func can_use() -> bool:
	if current_cooldown > 0.0:
		return false
	if not player:
		return false
	# Subclasses can override for additional checks
	return _can_use_custom()

## Virtual method - override for custom can_use logic
func _can_use_custom() -> bool:
	return true

## Activate the ability
func activate() -> void:
	if not can_use():
		print("[Ability] Cannot use %s - cooldown: %.1f" % [ability_name, current_cooldown])
		return
	
	print("[Ability] Activating: %s" % ability_name)
	
	# Start cooldown
	current_cooldown = cooldown
	ability_cooldown_started.emit(ability_name, cooldown)
	
	# Execute ability effect
	_execute()
	
	ability_activated.emit(ability_name)

## Virtual method - override to implement ability effect
func _execute() -> void:
	push_warning("[Ability] %s._execute() not implemented!" % ability_name)

## Update cooldown - call every frame
func update(delta: float) -> void:
	if current_cooldown > 0.0:
		current_cooldown -= delta
		if current_cooldown <= 0.0:
			current_cooldown = 0.0
			ability_ready.emit(ability_name)
	
	# Custom update logic
	_on_update(delta)

## Virtual method - override for custom update logic (e.g., duration effects)
func _on_update(_delta: float) -> void:
	pass

## Get cooldown progress (0.0 = ready, 1.0 = just used)
func get_cooldown_progress() -> float:
	if cooldown <= 0.0:
		return 0.0
	return current_cooldown / cooldown

## Check if ability is ready
func is_ready() -> bool:
	return current_cooldown <= 0.0

## Reset ability state
func reset() -> void:
	current_cooldown = 0.0
	_on_reset()

## Virtual method - override for custom reset logic
func _on_reset() -> void:
	pass

## Cleanup when ability is removed
func cleanup() -> void:
	_on_cleanup()
	player = null

## Virtual method - override for custom cleanup
func _on_cleanup() -> void:
	pass

## Get ability info dictionary
func get_info() -> Dictionary:
	return {
		"name": ability_name,
		"description": description,
		"icon": icon,
		"cooldown": cooldown,
		"current_cooldown": current_cooldown,
		"is_ready": is_ready(),
		"mana_cost": mana_cost,
		"health_cost": health_cost
	}
