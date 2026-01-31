extends CharacterBody2D
class_name UndeadExecutioner

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


@export var max_health := 1000.0
@export var damage := 20.0
@export var move_speed := 60.0
@export var melee_range := 100
@export var summon_cooldown := 15.0
@export var teleport_point_entry: Node2D
@export var hover_offset := 24.0
@export var attack_cooldown := 4.0

var summon_cd_left: float
var is_busy := false
var player: CharacterBody2D
var direction: int
var health: float
var teleport_points: Array[Node2D] = []
var attack_cooldown_remaining: float

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	health = max_health
	
	teleport_points.clear()
	if teleport_point_entry:
		for child in teleport_point_entry.get_children():
			# Expect marker nodes (Marker2D / Node2D). Store the Node2D so
			# behavior leaves can access `point.global_position`.
			if child is Node2D:
				teleport_points.append(child)
	else:
		push_warning("Undead Executioner: teleport_point_entry not assigned!")
		return

func _physics_process(delta):
	if summon_cd_left > 0:
		summon_cd_left -= delta
	
	if attack_cooldown_remaining > 0:
		attack_cooldown_remaining -= delta
		
	move_and_slide()

func take_damage(damage):
	health -= damage
	
func face_target(target: Node2D) -> void:
	if not target:
		return
	set_direction(target.global_position.x - global_position.x)

func set_direction(dir: int) -> void:
	if dir == 0:
		return
	direction = sign(dir)
	
	# Flip sprite
	animated_sprite_2d.flip_h = direction < 0
