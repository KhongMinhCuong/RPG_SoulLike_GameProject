extends State
class_name EnemyAttack

enum AttackType {
	MELEE,
	RANGED
}

@export var attack_type: AttackType = AttackType.MELEE

# chỉ dùng khi bắn vật thể
@export var projectile_spawn: Node2D
@export var projectile_scene: PackedScene

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var animated_sprite: AnimatedSprite2D = $"../../AnimatedSprite2D"
@onready var hitbox: Hitbox = $"../../Hitbox"

var monster: CharacterBody2D
var player: Node2D
var attack_timer: float = 0.0
var is_locked := false
var direction: int

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
	
	animated_sprite.flip_h = player.global_position.x < monster.global_position.x
	
	var distance = monster.global_position.distance_to(player.global_position)
	
	var target = monster.player
	direction = sign(target.global_position.x - monster.global_position.x)
	monster.direction = direction
		
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

	animated_sprite.play("attack")

	await animated_sprite.animation_finished
	
	_spawn_projectile()

	monster.is_attacking = false
	animated_sprite.play("idle")

func _spawn_projectile():
	var projectile = projectile_scene.instantiate()
	projectile_spawn.position.x = abs(projectile_spawn.position.x) * direction
	projectile.global_position = projectile_spawn.global_position
	projectile.direction = monster.direction
	

	get_tree().current_scene.add_child(projectile)
