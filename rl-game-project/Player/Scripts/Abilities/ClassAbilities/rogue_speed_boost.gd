## RogueSpeedBoost - Shadow Step ability cho Rogue
## Dash không cooldown trong 3 giây
class_name RogueSpeedBoost
extends "res://Player/Scripts/Abilities/ability_base.gd"

# === ABILITY CONFIG ===
var buff_duration: float = 3.0
var is_buff_active: bool = false
var buff_timer: float = 0.0

# Store original dash cooldown
var original_dash_cooldown: float = 0.0

func _on_initialize() -> void:
	ability_name = "Shadow Step"
	description = "Dash không cooldown trong 3 giây"
	cooldown = 12.0
	mana_cost = 0.0

func _execute() -> void:
	if not player:
		return
	
	is_buff_active = true
	buff_timer = buff_duration
	
	# Store và set dash cooldown về 0
	if player.runtime_stats:
		original_dash_cooldown = player.runtime_stats.dash_cooldown
		player.runtime_stats.dash_cooldown = 0.0
		player.runtime_stats.current_dash_cooldown = 0.0
	
	print("[Rogue] Shadow Step activated! Dash cooldown removed for %.1f seconds" % buff_duration)
	
	# Visual feedback
	_show_buff_effect()

func _on_update(delta: float) -> void:
	if not is_buff_active:
		return
	
	# Keep dash cooldown at 0 during buff
	if player and player.runtime_stats:
		player.runtime_stats.current_dash_cooldown = 0.0
	
	buff_timer -= delta
	if buff_timer <= 0.0:
		_end_buff()

func _end_buff() -> void:
	is_buff_active = false
	buff_timer = 0.0
	
	# Restore original dash cooldown
	if player and player.runtime_stats and original_dash_cooldown > 0:
		player.runtime_stats.dash_cooldown = original_dash_cooldown
	
	print("[Rogue] Shadow Step ended")

func _show_buff_effect() -> void:
	if player and player.has_node("Sprite2D"):
		var sprite = player.get_node("Sprite2D")
		# Purple shadow effect
		var tween = player.create_tween()
		tween.set_loops(3)
		tween.tween_property(sprite, "modulate", Color(0.7, 0.5, 1.0, 0.8), 0.15)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func _on_reset() -> void:
	if is_buff_active:
		_end_buff()
	is_buff_active = false
	buff_timer = 0.0

func has_buff() -> bool:
	return is_buff_active
