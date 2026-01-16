## NormalArrow - Mũi tên thường cho Archer
## Gây 150% damage cơ bản
class_name NormalArrow
extends "res://Player/Scripts/Projectiles/player_projectile.gd"

func _ready() -> void:
	super._ready()
	
	# Normal arrow: 150% damage
	# Damage được set từ bên ngoài khi spawn
	print("[NormalArrow] Spawned with damage: %.1f" % damage)

# KHÔNG override _calculate_damage() để sử dụng critical hit logic từ parent class
# func _calculate_damage() đã có trong PlayerProjectile với critical hit

func _on_destroy() -> void:
	# Có thể spawn particle effect
	pass
