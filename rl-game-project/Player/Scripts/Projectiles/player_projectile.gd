## PlayerProjectile - Base class cho tất cả đạn của Player
## Xử lý di chuyển, damage, và tự hủy
class_name PlayerProjectile
extends Area2D

# === PROJECTILE STATS ===
@export var speed: float = 400.0
@export var damage: float = 25.0
@export var lifetime: float = 3.0
@export var piercing: bool = false  # Xuyên qua enemy không?
@export var max_pierce_count: int = 3  # Số lần xuyên tối đa

# === STATE ===
var direction: Vector2 = Vector2.RIGHT
var owner_player: Node = null
var pierce_count: int = 0
var hit_enemies: Array[Node] = []  # Track enemies đã hit để không hit 2 lần

# === VISUAL ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

# === SIGNALS ===
signal hit_enemy(enemy: Node, damage: float)
signal projectile_destroyed()

func _ready() -> void:
	# Flip sprite theo hướng
	if direction.x < 0:
		scale.x = -1
	
	# Start lifetime timer
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(_on_lifetime_timeout)
	add_child(timer)
	timer.start()
	
	# Connect collision
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

## Setup projectile với direction và owner
func setup(dir: Vector2, player: Node = null, custom_damage: float = -1.0) -> void:
	direction = dir.normalized()
	owner_player = player
	
	if custom_damage > 0:
		damage = custom_damage
	elif player and player.base_stats:
		# Use player's damage stat
		damage = player.base_stats.base_damage

## Khi đạn hết lifetime
func _on_lifetime_timeout() -> void:
	_destroy()

## Khi va chạm với body (enemy)
func _on_body_entered(body: Node) -> void:
	_handle_hit(body)

## Khi va chạm với area (Hurtbox của enemy)
func _on_area_entered(area: Area2D) -> void:
	# Check if this is a hurtbox
	var body = area.get_parent()
	_handle_hit(body)

func _handle_hit(target: Node) -> void:
	# Skip nếu đã hit target này rồi
	if target in hit_enemies:
		return
	
	# Skip nếu là player hoặc player's nodes
	if target == owner_player or target.is_in_group("player"):
		return
	
	# Check nếu target có thể nhận damage
	if target.has_method("take_damage") or target.has_method("apply_damage"):
		hit_enemies.append(target)
		
		# Apply damage
		var final_damage = _calculate_damage()
		
		# Notify player's passives about damage dealt (for lifesteal, etc.)
		if owner_player and owner_player.has_node("AbilityManager"):
			var ability_mgr = owner_player.get_node("AbilityManager")
			final_damage = ability_mgr.notify_damage_dealt(final_damage, target)
		
		if target.has_method("take_damage"):
			target.take_damage(final_damage)
		elif target.has_method("apply_damage"):
			target.apply_damage(final_damage)
		
		hit_enemy.emit(target, final_damage)
		
		# Handle piercing
		if piercing:
			pierce_count += 1
			if pierce_count >= max_pierce_count:
				_destroy()
		else:
			_destroy()

## Calculate final damage (có thể override trong subclass)
func _calculate_damage() -> float:
	var final_damage = damage
	
	# Có thể thêm damage modifiers từ player
	if owner_player and owner_player.has_node("AbilityManager"):
		var _ability_mgr = owner_player.get_node("AbilityManager")
		# Notify passives có thể modify damage
		# (Lưu ý: cần implement notify_projectile_damage trong ability_manager)
	
	return final_damage

## Destroy projectile
func _destroy() -> void:
	projectile_destroyed.emit()
	# Play destroy animation/effect if any
	_on_destroy()
	queue_free()

## Virtual method - override cho custom destroy effects
func _on_destroy() -> void:
	pass
