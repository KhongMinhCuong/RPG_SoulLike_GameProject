extends Area2D
class_name Hurtbox

func _init() -> void:
	collision_layer = 1
	collision_mask = 3

func _ready() -> void:
	connect("area_entered", Callable(self, "_on_area_entered"))
	
func _on_area_entered(hitbox: Hitbox) -> void:
	print(owner, "got hit from", hitbox.owner)
	if hitbox == null:
		return
	
	if owner.has_method("take_damage"):
		owner.take_damage(hitbox.damage)
