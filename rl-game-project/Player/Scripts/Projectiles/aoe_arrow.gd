## AOEArrow - Mũi tên nổ cho Archer
## Gây 80% base damage qua explosion, tạo trap khi hit wall
class_name AOEArrow
extends "res://Player/Scripts/Projectiles/player_projectile.gd"

# === AOE CONFIG ===
@export var explosion_radius: float = 80.0
@export var explosion_damage_percent: float = 1.0  # 100% of arrow damage (arrow đã là 80% base)
@export var trap_duration: float = 3.0
@export var trap_damage_percent: float = 0.5  # 50% of arrow damage
@export var trap_tick_rate: float = 0.5  # Damage mỗi 0.5s

# Scenes
var explosion_effect_scene: PackedScene = null
var trap_scene: PackedScene = null
var is_exploding: bool = false  # Prevent multiple explosions

func _ready() -> void:
	super._ready()
	print("[AOEArrow] Spawned with arrow damage: %.1f, explosion will deal: %.1f" % [damage, damage * explosion_damage_percent])
	
	# Try to load effect scenes
	if ResourceLoader.exists("res://Player/Scenes/Projectiles/Effects/explosion_effect.tscn"):
		explosion_effect_scene = load("res://Player/Scenes/Projectiles/Effects/explosion_effect.tscn")
	if ResourceLoader.exists("res://Player/Scenes/Projectiles/Effects/arrow_trap.tscn"):
		trap_scene = load("res://Player/Scenes/Projectiles/Effects/arrow_trap.tscn")

func _handle_hit(target: Node) -> void:
	# Skip nếu đã hit target này rồi
	if target in hit_enemies:
		return
	
	# Skip nếu đang exploding (prevent double explosion)
	if is_exploding:
		return
	
	# Skip player
	if target == owner_player or target.is_in_group("player"):
		return
	
	# Mark as exploding
	is_exploding = true
	hit_enemies.append(target)
	
	# Check nếu hit enemy hay wall
	if target.is_in_group("enemy") or target.has_method("take_damage"):
		# Hit enemy -> Explosion (KHÔNG gây damage trực tiếp, để explosion xử lý)
		_create_explosion()
	elif target.is_in_group("wall") or target is TileMap or target is StaticBody2D:
		# Hit wall -> Create trap
		_create_trap()
	else:
		# Unknown target, treat as explosion
		_create_explosion()
	
	_destroy()

func _create_explosion() -> void:
	"""Tạo explosion gây damage AoE - TẤT CẢ damage đều từ explosion, không có direct hit"""
	# Spawn explosion effect với hitbox
	var explosion = _spawn_explosion_with_damage()
	if explosion:
		print("[AOEArrow] Explosion created at %s" % global_position)

func _spawn_explosion_with_damage() -> Node:
	"""Spawn explosion effect với Hitbox để gây damage - sử dụng cùng hệ thống như Player hitbox"""
	# Tạo explosion node với direction property (để Hitbox không bị lỗi)
	var explosion = Node2D.new()
	explosion.global_position = global_position
	explosion.set_meta("direction", 1)  # Default direction
	explosion.set_meta("damage", damage * explosion_damage_percent)
	
	# Tạo Hitbox (extends Area2D) để gây damage - giống hitbox của player
	var hitbox = Hitbox.new()
	hitbox.name = "ExplosionHitbox"
	var explosion_dmg = damage * explosion_damage_percent
	hitbox.damage = explosion_dmg
	hitbox.direction = 1  # Set direction trực tiếp trên hitbox
	print("[AOEArrow] Explosion hitbox damage set to: %.1f (arrow: %.1f × %.1f)" % [explosion_dmg, damage, explosion_damage_percent])
	# Override collision settings cho AOE
	hitbox.collision_layer = 3  # Hitbox layer
	hitbox.collision_mask = 1   # Detect Hurtbox (layer 1)
	explosion.add_child(hitbox)
	
	# QUAN TRỌNG: Set owner_node sau khi add_child để override _ready()
	hitbox.owner_node = explosion
	
	# Tạo collision shape (circle) cho hitbox
	var explosion_collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = explosion_radius
	explosion_collision.shape = circle
	hitbox.add_child(explosion_collision)
	
	# Spawn visual effect
	if explosion_effect_scene:
		var effect = explosion_effect_scene.instantiate()
		explosion.add_child(effect)
	else:
		# Fallback: simple explosion visual (màu cam/đỏ cho lửa)
		var particles = CPUParticles2D.new()
		particles.emitting = true
		particles.one_shot = true
		particles.explosiveness = 0.9
		particles.amount = 25
		particles.lifetime = 0.4
		particles.direction = Vector2(0, -1)
		particles.spread = 180
		particles.initial_velocity_min = 80
		particles.initial_velocity_max = 150
		particles.gravity = Vector2(0, 50)
		# Màu lửa: đỏ -> cam -> vàng
		var gradient = Gradient.new()
		gradient.set_offset(0, 0.0)
		gradient.set_color(0, Color(1.0, 0.3, 0.1, 1.0))  # Đỏ cam
		gradient.add_point(0.5, Color(1.0, 0.6, 0.1, 0.8))  # Cam
		gradient.set_offset(1, 1.0)
		gradient.set_color(1, Color(1.0, 0.9, 0.2, 0.0))  # Vàng fade
		particles.color_ramp = gradient
		explosion.add_child(particles)
	
	# Add to scene FIRST
	get_tree().current_scene.add_child(explosion)
	
	# Enable hitbox ngay lập tức để detect
	hitbox.enable()
	
	# Tạo timer để disable hitbox sau 2 physics frames (TRÊN explosion node, không phải arrow)
	var disable_timer = Timer.new()
	disable_timer.wait_time = 0.05  # ~2-3 physics frames
	disable_timer.one_shot = true
	disable_timer.autostart = true
	explosion.add_child(disable_timer)
	disable_timer.timeout.connect(func():
		if is_instance_valid(hitbox):
			hitbox.disable()
			# Xóa hitbox hoàn toàn để không còn detect được
			hitbox.queue_free()
	)
	
	# Tạo timer để cleanup explosion sau khi visual effect hoàn thành
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 0.7
	cleanup_timer.one_shot = true
	cleanup_timer.autostart = true
	explosion.add_child(cleanup_timer)
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(explosion):
			explosion.queue_free()
	)
	
	return explosion

func _create_trap() -> void:
	"""Tạo trap tại vị trí hit wall"""
	if trap_scene:
		var trap = trap_scene.instantiate()
		trap.global_position = global_position
		trap.setup(damage * trap_damage_percent, trap_duration, trap_tick_rate, owner_player)
		get_tree().current_scene.add_child(trap)
		print("[AOEArrow] Trap created at %s" % global_position)
	else:
		# Fallback: spawn simple trap
		_spawn_simple_trap()

func _spawn_explosion_effect() -> void:
	"""Spawn visual explosion effect"""
	if explosion_effect_scene:
		var effect = explosion_effect_scene.instantiate()
		effect.global_position = global_position
		get_tree().current_scene.add_child(effect)
	else:
		# Simple flash effect
		pass

func _spawn_simple_trap() -> void:
	"""Tạo trap đơn giản nếu không có scene"""
	var trap = ArrowTrap.new()
	trap.global_position = global_position
	trap.setup(damage * trap_damage_percent, trap_duration, trap_tick_rate, owner_player)
	get_tree().current_scene.add_child(trap)
