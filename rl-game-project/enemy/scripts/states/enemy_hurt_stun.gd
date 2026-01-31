extends State
class_name EnemyHurtStun

@onready var enemy: EnemyBase = owner

@export var normal_stun := 0.8
@export var parry_extra_stun := 1.5  # thời gian cộng thêm khi bị parry

var stun_time := 0.0

func enter():
	enemy.velocity.x = 0
	
	if enemy.is_parry_stun:
		stun_time = enemy.stun_duration + parry_extra_stun
	else:
		stun_time = normal_stun

	enemy.is_parry_stun = false
	
	if enemy.animated_sprite:
		enemy.animated_sprite.play("hurt")
		enemy.animated_sprite.animation_finished.connect(play_idle_animation)
func update(delta):
	stun_time -= delta

	if stun_time <= 0:
		emit_signal("transition", self, "EnemyAttack")

func physic_update(delta):
	pass

func play_idle_animation():
	enemy.animated_sprite.play("idle")
