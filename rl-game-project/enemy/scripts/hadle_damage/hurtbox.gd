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
	
	# Prevent self-damage and friendly fire within same group
	if hitbox.owner_node == owner:
		return  # Don't damage self
	
	# Check if both are in "Player" group (prevent player attacking player)
	if owner.is_in_group("Player") and hitbox.owner_node and hitbox.owner_node.is_in_group("Player"):
		return
	
	# Check if both are in "Enemy" group (prevent enemy attacking enemy)
	if owner.is_in_group("Enemy") and hitbox.owner_node and hitbox.owner_node.is_in_group("Enemy"):
		return
	
	# Always call take_damage on owner first
	if owner.has_method("take_damage"):
		owner.take_damage(hitbox.damage)
	
	# PARRY MECHANIC: If owner is parrying, counter-attack the attacker
	if owner.has_method("get") and owner.get("is_parrying") == true:
		print(owner, "parried attack from", hitbox.owner_node, "- counter-attacking!")
		# Counter-attack: trigger parry stun on attacker
		if hitbox.owner_node and hitbox.owner_node.has_method("take_damage"):
			# Pass is_parry=true to trigger extended stun duration
			hitbox.owner_node.take_damage(0, true)
