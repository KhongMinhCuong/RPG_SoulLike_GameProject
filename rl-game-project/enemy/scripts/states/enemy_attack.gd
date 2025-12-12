extends State
class_name EnemyAttack

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var animated_sprite: AnimatedSprite2D = $"../../AnimatedSprite2D"
@onready var hitbox: Hitbox = $"../../Hitbox"

var monster: CharacterBody2D
var player: Node2D
var attack_timer: float = 0.0

func enter() -> void:
	print("ATTACK")
	monster = owner if owner else get_parent().owner
	if not monster:
		push_error("EnemyAttack: Monster reference is null!")
		return
	
	player = monster.player
	attack_timer = 0.0
	monster.is_attacking = false
	animated_sprite.play("idle")

func exit() -> void:
	animated_sprite.play("idle")
	monster.velocity.x = 0
	monster.is_attacking = false

func update(delta: float) -> void:
	if not monster or not player:
		return

	var distance = monster.global_position.distance_to(player.global_position)

	# Back to chase
	if distance > monster.attack_range * 1.5:
		emit_signal("transition", self, "EnemyChase")
		return

	# Cooldown
	if attack_timer > 0:
		attack_timer -= delta
		return

	if not monster.is_attacking:
		_perform_attack()

func _perform_attack() -> void:
	if monster.is_attacking:
		return
	
	monster.is_attacking = true
	attack_timer = monster.attack_cooldown
	
	hitbox.enable()
	animation_player.play("attack")
	
	animated_sprite.flip_h = player.global_position.x < monster.global_position.x

	await animation_player.animation_finished
	hitbox.disable()
	monster.is_attacking = false
	animated_sprite.play("idle")
