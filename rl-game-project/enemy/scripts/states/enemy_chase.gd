extends State
class_name EnemyChase

@onready var animated_sprite: AnimatedSprite2D = $"../../AnimatedSprite2D"

var monster
var player: Node2D

func enter():
	print("CHASE")
	monster = owner if owner else get_parent().owner
	player = monster.player

	if not player:
		return

	animated_sprite.play("walk")

func exit():
	monster.velocity.x = 0
	animated_sprite.play("idle")

func update(delta):
	if not monster or not player:
		return

	# distance check: horizontal for ground enemies, full 2D for flying
	var distance := 0.0
	if "is_flying" in monster and monster.is_flying:
		distance = monster.global_position.distance_to(player.global_position)
	else:
		distance = abs(player.global_position.x - monster.global_position.x)

	if distance > monster.detection_range:
		emit_signal("transition", self, "EnemyIdle")
		return

	if distance <= monster.attack_range:
		emit_signal("transition", self, "EnemyAttack")
		return

func physic_update(delta: float) -> void:
	if not monster or not player:
		return
	# distance check for physics as well
	var distance := 0.0
	if "is_flying" in monster and monster.is_flying:
		distance = monster.global_position.distance_to(player.global_position)
	else:
		distance = abs(player.global_position.x - monster.global_position.x)

	if distance > monster.detection_range:
		emit_signal("transition", self, "EnemyIdle")
		return

	if "is_flying" in monster and monster.is_flying:
		# 2D movement towards player; aim slightly above player using hover_offset if present
		var target = player.global_position
		if "hover_offset" in monster:
			target = player.global_position + Vector2(0, -(monster.hover_offset if "hover_offset" in monster else 24.0))
		var vec = target - monster.global_position
		if vec.length() > 0.01:
			monster.velocity = vec.normalized() * monster.chase_speed
		else:
			monster.velocity = Vector2.ZERO
		# flip based on horizontal velocity
		if animated_sprite:
			animated_sprite.flip_h = monster.velocity.x < 0
		monster.move_and_slide()
	else:
		var direction = sign(player.global_position.x - monster.global_position.x)
		monster.velocity.x = direction * monster.chase_speed
		monster.direction = direction

		animated_sprite.flip_h = direction < 0
		monster.move_and_slide()
