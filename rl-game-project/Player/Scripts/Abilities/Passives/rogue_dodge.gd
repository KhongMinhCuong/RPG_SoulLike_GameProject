## RogueDodge - Passive né tránh cho Rogue
## 15% chance né hoàn toàn damage
class_name RogueDodge
extends "res://Player/Scripts/Abilities/passive_base.gd"

# === PASSIVE CONFIG ===
var dodge_chance: float = 0.15  # 15% dodge chance
var dodge_chance_per_luck: float = 0.01  # +1% per luck point

func _on_initialize() -> void:
	passive_name = "Evasion"
	description = "15% cơ hội né hoàn toàn damage (tăng theo Luck)"

## Override on_damage_taken để có chance né
func _on_damage_taken(damage: float) -> float:
	if not player or not is_active:
		return damage
	
	# Tính dodge chance (base + luck bonus)
	var total_dodge_chance = dodge_chance
	if player.base_stats:
		total_dodge_chance += player.base_stats.luck * dodge_chance_per_luck
	total_dodge_chance = min(total_dodge_chance, 0.5)  # Cap 50%
	
	# Roll dodge
	if randf() < total_dodge_chance:
		print("[Rogue Passive] DODGED! (%.1f%% chance)" % (total_dodge_chance * 100))
		trigger()  # Trigger visual effect
		passive_effect_applied.emit(passive_name, 0.0)
		return 0.0  # Né hoàn toàn
	
	return damage

func _on_trigger() -> void:
	# Dodge visual effect
	if player and player.has_node("Sprite2D"):
		var sprite = player.get_node("Sprite2D")
		# Ghost/transparent effect
		var tween = player.create_tween()
		tween.tween_property(sprite, "modulate:a", 0.3, 0.1)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.2)

## Show dodge text above player (optional)
func _show_dodge_text() -> void:
	# Có thể spawn floating text "DODGE!"
	pass
