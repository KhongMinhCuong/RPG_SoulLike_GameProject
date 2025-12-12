extends State
class_name EnemyIdle

@onready var animated_sprite: AnimatedSprite2D = $"../../AnimatedSprite2D"

var monster: EnemyBase
var player: Node2D
@export var idle_time := 1.0
var timer := 0.0

func enter():
	print("IDLE")
	monster = owner as EnemyBase
	if monster == null:
		monster = get_parent().owner as EnemyBase

	player = monster.player

	timer = idle_time
	monster.velocity.x = 0
	animated_sprite.play("idle")

func update(delta):
	if not monster or not player:
		return

	if monster.global_position.distance_to(player.global_position) < monster.chase_range:
		emit_signal("transition", self, "enemychase")
		return

	# chờ bình thường, không phát hiện thì sang patrol
	timer -= delta
	if timer <= 0:
		emit_signal("transition", self, "enemypatrol")
