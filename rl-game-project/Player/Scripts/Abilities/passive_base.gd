## PassiveBase - Base class cho tất cả Passive Abilities
## Passives tự động kích hoạt dựa trên điều kiện hoặc luôn active
## Không có cooldown, không cần input
class_name PassiveBase
extends RefCounted

# === PASSIVE INFO ===
var passive_name: String = "Base Passive"
var description: String = "Passive description"
var icon: Texture2D = null

# === STATE ===
var is_active: bool = true  # Passive có đang hoạt động không
var is_triggered: bool = false  # For conditional passives

# === REFERENCES ===
var player: Node = null

# === SIGNALS ===
signal passive_triggered(passive_name: String)
@warning_ignore("unused_signal")
signal passive_effect_applied(passive_name: String, value: float)

## Initialize passive with player reference
func initialize(player_ref: Node) -> void:
	player = player_ref
	is_active = true
	is_triggered = false
	_on_initialize()

## Virtual method - override for custom initialization
## Connect signals, apply permanent effects, etc.
func _on_initialize() -> void:
	pass

## Apply permanent stat modifiers (called once on init)
func apply_stat_modifiers() -> void:
	_apply_stat_modifiers()

## Virtual method - override to apply stat modifiers
func _apply_stat_modifiers() -> void:
	pass

## Remove stat modifiers (called on cleanup)
func remove_stat_modifiers() -> void:
	_remove_stat_modifiers()

## Virtual method - override to remove stat modifiers
func _remove_stat_modifiers() -> void:
	pass

## Update passive - call every frame
func update(delta: float) -> void:
	if not is_active:
		return
	_on_update(delta)

## Virtual method - override for frame-based passive logic
func _on_update(_delta: float) -> void:
	pass

## Called when player takes damage (before damage is applied)
## Return modified damage amount
func on_damage_taken(damage: float) -> float:
	return _on_damage_taken(damage)

## Virtual method - override for damage reduction passives
func _on_damage_taken(damage: float) -> float:
	return damage  # No modification by default

## Called when player deals damage
## Return modified damage amount
func on_damage_dealt(damage: float, target: Node) -> float:
	return _on_damage_dealt(damage, target)

## Virtual method - override for damage boost passives
func _on_damage_dealt(damage: float, _target: Node) -> float:
	return damage  # No modification by default

## Called when player attacks (before damage calculation)
func on_attack() -> void:
	_on_attack()

## Virtual method - override for attack-triggered passives
func _on_attack() -> void:
	pass

## Called when player kills an enemy
func on_kill(enemy: Node) -> void:
	_on_kill(enemy)

## Virtual method - override for kill-triggered passives
func _on_kill(_enemy: Node) -> void:
	pass

## Called when player dashes
func on_dash() -> void:
	_on_dash()

## Virtual method - override for dash-triggered passives
func _on_dash() -> void:
	pass

## Called when player parries successfully
func on_parry_success() -> void:
	_on_parry_success()

## Virtual method - override for parry-triggered passives
func _on_parry_success() -> void:
	pass

## Called when player's health changes
func on_health_changed(current: float, max_health: float) -> void:
	_on_health_changed(current, max_health)

## Virtual method - override for health-based passives
func _on_health_changed(_current: float, _max_health: float) -> void:
	pass

## Enable/disable passive
func set_active(active: bool) -> void:
	if is_active == active:
		return
	is_active = active
	if active:
		_on_activate()
	else:
		_on_deactivate()

## Virtual method - override for activation logic
func _on_activate() -> void:
	pass

## Virtual method - override for deactivation logic
func _on_deactivate() -> void:
	pass

## Trigger conditional passive effect
func trigger() -> void:
	if not is_active:
		return
	is_triggered = true
	passive_triggered.emit(passive_name)
	_on_trigger()

## Virtual method - override for trigger effect
func _on_trigger() -> void:
	pass

## Reset passive state
func reset() -> void:
	is_triggered = false
	_on_reset()

## Virtual method - override for custom reset logic
func _on_reset() -> void:
	pass

## Cleanup when passive is removed
func cleanup() -> void:
	remove_stat_modifiers()
	_on_cleanup()
	player = null

## Virtual method - override for custom cleanup
func _on_cleanup() -> void:
	pass

## Get passive info dictionary
func get_info() -> Dictionary:
	return {
		"name": passive_name,
		"description": description,
		"icon": icon,
		"is_active": is_active,
		"is_triggered": is_triggered
	}
