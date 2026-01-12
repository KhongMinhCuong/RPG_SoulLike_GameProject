## NormalArrow - Mũi tên thường cho Archer
## Gây 150% damage cơ bản
class_name NormalArrow
extends "res://Player/Scripts/Projectiles/player_projectile.gd"

func _ready() -> void:
	super._ready()
	
	# Normal arrow: 150% damage
	# Damage được set từ bên ngoài khi spawn

func _calculate_damage() -> float:
	# Normal arrow đã có damage multiplier được apply khi spawn
	return damage

func _on_destroy() -> void:
	# Có thể spawn particle effect
	pass
