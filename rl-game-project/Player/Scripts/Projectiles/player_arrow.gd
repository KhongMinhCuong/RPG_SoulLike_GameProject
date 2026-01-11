## PlayerArrow - Mũi tên của Archer
## Kế thừa PlayerProjectile, có thể piercing
class_name PlayerArrow
extends "res://Player/Scripts/Projectiles/player_projectile.gd"

# === ARROW SPECIFIC ===
@export var arrow_type: String = "normal"  # normal, fire, ice, piercing

# === PIERCING ARROW BONUS ===
var piercing_damage_reduction: float = 0.15  # Giảm 15% damage mỗi lần xuyên

func _ready() -> void:
	super._ready()
	
	# Set arrow-specific defaults
	if arrow_type == "piercing":
		piercing = true
		max_pierce_count = 5

## Override damage calculation cho arrow
func _calculate_damage() -> float:
	var final_damage = damage
	
	# Piercing arrows giảm damage mỗi lần xuyên
	if piercing and pierce_count > 0:
		final_damage *= (1.0 - piercing_damage_reduction * pierce_count)
		final_damage = max(final_damage * 0.3, final_damage)  # Min 30% damage
	
	return final_damage

## Override destroy để spawn hiệu ứng
func _on_destroy() -> void:
	# Có thể spawn particle effect ở đây
	pass
