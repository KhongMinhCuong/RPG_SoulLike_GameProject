extends State
class_name EnemyAttack

@onready var animated_sprite: AnimatedSprite2D = $"../../AnimatedSprite2D"
@onready var hitbox: Hitbox = $"../../Hitbox"

var monster: CharacterBody2D
var player: Node2D
var attack_timer: float = 0.0
var attacking: bool = false

func enter() -> void:
	print("ATTACK")
	monster = owner if owner else get_parent().owner
	if not monster:
		push_error("EnemyAttack: Monster reference is null!")
		return
	
	player = monster.player
	attack_timer = 0.0
	attacking = false
	animated_sprite.play("idle")

func exit() -> void:
	animated_sprite.play("idle")
	monster.velocity.x = 0
	attacking = false

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

	if not attacking:
		_perform_attack()

func _perform_attack() -> void:
	if attacking:
		return
	attacking = true
	attack_timer = monster.attack_cooldown
	
	hitbox.enable()
	animated_sprite.play("attack")

	animated_sprite.flip_h = player.global_position.x < monster.global_position.x

	await animated_sprite.animation_finished
	hitbox.disable()
	attacking = false
	animated_sprite.play("idle")
