extends State
class_name EnemyAttack

enum AttackType {
	MELEE,
	RANGED
}

@export var attack_type: AttackType = AttackType.MELEE

# chỉ dùng khi bắn vật thể
@export var projectile_spawn: Node2D
var projectile_scene = preload("res://enemy/scenes/arrow.tscn")

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var animated_sprite: AnimatedSprite2D = $"../../AnimatedSprite2D"
@onready var hitbox: Hitbox = $"../../Hitbox"

var monster: CharacterBody2D
var player: Node2D
var attack_timer: float = 0.0
var is_locked := false

func enter():
	print("ATTACK")
	monster = owner if owner else get_parent().owner
	
	player = monster.player
	attack_timer = 0.0
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
		match attack_type:
			AttackType.MELEE:
				_melee_attack()
			AttackType.RANGED:
				_ranged_attack()

func _melee_attack() -> void:
	if monster.is_attacking:
		return
	
	monster.is_attacking = true
	attack_timer = monster.attack_cooldown
	
	animation_player.play("attack")
	
	animated_sprite.flip_h = player.global_position.x < monster.global_position.x

	await animation_player.animation_finished
	monster.is_attacking = false
	animated_sprite.play("idle")

func _ranged_attack() -> void:
	if not projectile_scene or not projectile_spawn:
		push_error("EnemyAttack: Missing projectile setup!")
		return
	if monster.is_attacking:
		return
	
	monster.is_attacking = true
	attack_timer = monster.attack_cooldown

	animated_sprite.flip_h = player.global_position.x < monster.global_position.x
	animated_sprite.play("attack")

	await animated_sprite.animation_finished

	_spawn_projectile()

	monster.is_attacking = false
	animated_sprite.play("idle")

func _spawn_projectile():
	var projectile = projectile_scene.instantiate()
	projectile.global_position = projectile_spawn.global_position
	projectile.direction = monster.direction

	# Optional interface
	if projectile.has_method("set_direction"):
		projectile.set_direction(
			sign(player.global_position.x - monster.global_position.x)
		)

	get_tree().current_scene.add_child(projectile)
