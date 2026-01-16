## ExplosionEffect - Visual effect for AOE arrow explosion
extends Node2D

func _on_timer_timeout() -> void:
	queue_free()
