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

	var distance = abs(player.global_position.x - monster.global_position.x)

	if distance > monster.detection_range:
		if monster.has_node("PatrolPoints"):
			emit_signal("transition", self, "EnemyPatrol")
		else:
			emit_signal("transition", self, "EnemyIdle")
		return

	if distance <= monster.stop_distance:
		emit_signal("transition", self, "EnemyAttack")
		return

func physic_update(delta: float) -> void:
	if not monster or not player:
		return
	
	var distance = abs(player.global_position.x - monster.global_position.x)

	if distance > monster.detection_range:
		emit_signal("transition", self, "EnemyPatrol")
		return

	var direction = sign(player.global_position.x - monster.global_position.x)
	monster.velocity.x = direction * monster.move_speed

	if not monster.is_on_floor():
		monster.velocity.y += monster.gravity * delta
	else:
		monster.velocity.y = 0

	animated_sprite.flip_h = direction < 0
	monster.move_and_slide()
