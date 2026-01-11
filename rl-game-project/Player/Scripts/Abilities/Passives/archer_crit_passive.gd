## ArcherComboSpeed - Passive tốc độ đánh cho Archer
## Mỗi lần hoàn thành combo (3_atk) tăng 10% attack speed
## Tối đa 10 stacks = 200% attack speed
class_name ArcherCritPassive
extends "res://Player/Scripts/Abilities/passive_base.gd"

# === COMBO SPEED CONFIG ===
var speed_bonus_per_stack: float = 0.10  # +10% per stack
var max_stacks: int = 10  # Max 10 stacks = +100% (200% total)
var current_stacks: int = 0

# === DECAY CONFIG ===
var decay_timer: float = 0.0
var decay_delay: float = 5.0  # Bắt đầu decay sau 5s không attack
var decay_rate: float = 1.0  # Mất 1 stack mỗi giây khi decay

func _on_initialize() -> void:
	passive_name = "Rapid Fire"
	description = "Hoàn thành combo (3_atk) tăng 10% tốc độ đánh. Tối đa 10 stacks (200% speed)"
	current_stacks = 0
	decay_timer = 0.0

func _on_update(delta: float) -> void:
	if not player or not is_active or current_stacks == 0:
		return
	
	# Reset tất cả stacks sau 5 giây không hoàn thành combo
	decay_timer += delta
	if decay_timer >= decay_delay:
		# Reset hoàn toàn thay vì decay từ từ
		print("[Archer Passive] No combo in %.1fs - stacks reset from %d to 0" % [decay_delay, current_stacks])
		reset_stacks()

## Gọi khi player hoàn thành 3_atk
func on_combo_completed() -> void:
	if not is_active:
		return
	
	# Reset decay timer
	decay_timer = 0.0
	
	# Add stack
	if current_stacks < max_stacks:
		current_stacks += 1
		_update_attack_speed()
		print("[Archer Passive] Combo completed! Stacks: %d, Speed: %.0f%%" % [
			current_stacks, get_attack_speed_multiplier() * 100
		])
		
		trigger()  # Visual effect

func _update_attack_speed() -> void:
	"""Cập nhật attack speed cho player"""
	if player and player.runtime_stats:
		var multiplier = get_attack_speed_multiplier()
		player.runtime_stats.attack_speed_multiplier = multiplier

func get_attack_speed_multiplier() -> float:
	"""Trả về attack speed multiplier hiện tại"""
	return 1.0 + (current_stacks * speed_bonus_per_stack)

func get_current_stacks() -> int:
	return current_stacks

## Reset stacks khi chết hoặc reset game
func reset_stacks() -> void:
	current_stacks = 0
	decay_timer = 0.0
	_update_attack_speed()

func _on_trigger() -> void:
	# Visual effect khi gain stack
	if player and player.has_node("Sprite2D"):
		var sprite = player.get_node("Sprite2D")
		var tween = player.create_tween()
		# Quick green flash
		tween.tween_property(sprite, "modulate", Color(0.8, 1.2, 0.8), 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _on_reset() -> void:
	reset_stacks()
