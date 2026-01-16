## ArrowTrap - Bẫy mũi tên AOE khi chạm tường
## Gây damage liên tục cho enemies đi vào vùng bẫy
extends Node2D

@export var trap_damage: float = 15.0
@export var duration: float = 3.0
@export var tick_rate: float = 0.5

var owner_player: Node = null
var time_elapsed: float = 0.0
var tick_timer: float = 0.0
var enemies_in_trap: Array = []

@onready var damage_area: Area2D = $DamageArea
@onready var particles: CPUParticles2D = $Particles
@onready var warning_sprite: Sprite2D = $WarningSprite

func _ready() -> void:
	# Setup damage_area collision mask nếu chưa có
	if damage_area:
		damage_area.collision_layer = 0
		damage_area.collision_mask = 0b11111111  # Bao gồm layer 1 (enemy hurtbox)
		damage_area.monitoring = true
		damage_area.monitorable = false
		
		# Connect signals
		damage_area.area_entered.connect(_on_area_entered)
		damage_area.area_exited.connect(_on_area_exited)
		damage_area.body_entered.connect(_on_body_entered)
		damage_area.body_exited.connect(_on_body_exited)
	else:
		# Tạo damage_area nếu không có trong scene
		_create_damage_area()
	
	# Start particles
	if particles:
		particles.emitting = true
	
	# Animate warning sprite
	if warning_sprite:
		var tween = create_tween().set_loops()
		tween.tween_property(warning_sprite, "modulate:a", 0.3, 0.5)
		tween.tween_property(warning_sprite, "modulate:a", 1.0, 0.5)
	
	# Gây damage ngay lập tức cho enemies đang ở trong vùng
	_initial_damage_check.call_deferred()

func _create_damage_area() -> void:
	"""Tạo damage area nếu không có trong scene"""
	damage_area = Area2D.new()
	damage_area.name = "DamageArea"
	damage_area.collision_layer = 0
	damage_area.collision_mask = 0b11111111  # Bao gồm layer 1 (enemy hurtbox)
	damage_area.monitoring = true
	damage_area.monitorable = false
	add_child(damage_area)
	
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 50.0
	collision.shape = circle
	damage_area.add_child(collision)
	
	# Connect signals
	damage_area.area_entered.connect(_on_area_entered)
	damage_area.area_exited.connect(_on_area_exited)
	damage_area.body_entered.connect(_on_body_entered)
	damage_area.body_exited.connect(_on_body_exited)

func _initial_damage_check() -> void:
	"""Check và gây damage cho enemies đã ở trong vùng khi trap spawn"""
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	if not damage_area:
		return
	
	# Check overlapping areas
	for area in damage_area.get_overlapping_areas():
		_on_area_entered(area)
	
	# Check overlapping bodies
	for body in damage_area.get_overlapping_bodies():
		_on_body_entered(body)

func _process(delta: float) -> void:
	time_elapsed += delta
	tick_timer += delta
	
	# Deal damage every tick
	if tick_timer >= tick_rate:
		tick_timer = 0.0
		_deal_tick_damage()
	
	# Fade out near end of life
	if time_elapsed >= duration - 0.5:
		var fade = 1.0 - (time_elapsed - (duration - 0.5)) / 0.5
		modulate.a = fade
	
	# Destroy when duration ends
	if time_elapsed >= duration:
		queue_free()

func _deal_tick_damage() -> void:
	"""Gây damage cho tất cả enemies trong trap"""
	for enemy in enemies_in_trap:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(trap_damage)
			print("[ArrowTrap] Tick damage %.1f to %s" % [trap_damage, enemy.name])

func _on_area_entered(area: Area2D) -> void:
	# Hurtbox.owner là enemy, không phải get_parent()
	var target = area.owner if area.owner else area.get_parent()
	if not target or target == owner_player or target.is_in_group("player"):
		return
	if target not in enemies_in_trap:
		if target.has_method("take_damage"):
			enemies_in_trap.append(target)
			# Gây damage ngay khi vào
			target.take_damage(trap_damage)
			print("[ArrowTrap] Enemy entered: %s, dealt %.1f damage" % [target.name, trap_damage])
		elif target.has_method("apply_damage"):
			enemies_in_trap.append(target)
			target.apply_damage(trap_damage)

func _on_area_exited(area: Area2D) -> void:
	var target = area.owner if area.owner else area.get_parent()
	if target and target in enemies_in_trap:
		enemies_in_trap.erase(target)

func _on_body_entered(body: Node) -> void:
	if body == owner_player or body.is_in_group("player"):
		return
	if body not in enemies_in_trap:
		if body.has_method("take_damage"):
			enemies_in_trap.append(body)
			body.take_damage(trap_damage)
			print("[ArrowTrap] Enemy body entered: %s, dealt %.1f damage" % [body.name, trap_damage])
		elif body.has_method("apply_damage"):
			enemies_in_trap.append(body)
			body.apply_damage(trap_damage)

func _on_body_exited(body: Node) -> void:
	if body in enemies_in_trap:
		enemies_in_trap.erase(body)

## Setup trap với custom values
func setup(dmg: float, dur: float, tick: float, player: Node = null) -> void:
	trap_damage = dmg
	duration = dur
	tick_rate = tick
	owner_player = player
