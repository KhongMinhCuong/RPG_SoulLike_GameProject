extends State
class_name EnemyPatrol

@export var patrol_points: Node2D

@onready var animated_sprite: AnimatedSprite2D = $"../../AnimatedSprite2D"

var monster: CharacterBody2D
var player: Node2D

var current_target_index := 0
var points: Array[Vector2] = []
var direction := 0
var waiting := false
var wait_timer := 0.0

func enter() -> void:
	print("PATROL")
	monster = owner if owner else get_parent().owner
	if not monster:
		push_error("EnemyPatrol: Monster reference is null!")
		return

	player = monster.player

	points.clear()
	if patrol_points:
		for child in patrol_points.get_children():
			if child is Node2D:
				points.append(child.global_position)
	else:
		push_warning("EnemyPatrol: patrol_points not assigned!")
		return

	if points.is_empty():
		push_warning("EnemyPatrol: No patrol points found!")
		return

	current_target_index = 0
	_update_direction_to_target()
	waiting = false
	wait_timer = 0.0

func exit() -> void:
	monster.velocity.x = 0
	waiting = false
	wait_timer = 0.0

func update(delta: float) -> void:
	if not monster or not player:
		return

	var distance = abs(player.global_position.x - monster.global_position.x)
	
	if distance < monster.chase_range:
		emit_signal("transition", self, "EnemyChase")

func physic_update(delta: float) -> void:
	if not monster:
		return

	# Gravity
	if not monster.is_on_floor():
		monster.velocity.y += monster.gravity * delta
	else:
		monster.velocity.y = 0

	if points.is_empty():
		monster.move_and_slide()
		return

	if waiting:
		wait_timer -= delta
		monster.velocity.x = 0
		animated_sprite.play("idle")

		if wait_timer <= 0:
			waiting = false
			_move_to_next_point()

		monster.move_and_slide()
		return

	var target = points[current_target_index].x
	var distance = target - monster.global_position.x

	if abs(distance) > 5.0:
		direction = sign(distance)
		monster.velocity.x = monster.move_speed * direction
		animated_sprite.play("walk")
	else:
		waiting = true
		wait_timer = randf_range(monster.wait_time_range.x, monster.wait_time_range.y)
		monster.velocity.x = 0

	animated_sprite.flip_h = direction < 0
	monster.move_and_slide()

func _update_direction_to_target() -> void:
	var target = points[current_target_index].x
	direction = sign(target - monster.global_position.x)
	monster.direction = direction
	
	if direction == 0:
		direction = 1

func _move_to_next_point() -> void:
	current_target_index = (current_target_index + 1) % points.size()
	_update_direction_to_target()
