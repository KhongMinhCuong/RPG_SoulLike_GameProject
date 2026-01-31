extends CharacterBody2D
class_name Boss

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var move_speed := 60.0
@export var melee_range := 70.0
@export var summon_cooldown := 15.0
@export var teleport_points: Array[Node2D]
@export var max_health := 1000.0

var summon_cd_left := 0.0
var is_busy := false
var player: CharacterBody2D
var direction: int

func _ready():
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta):
	if summon_cd_left > 0:
		summon_cd_left -= delta
	
	move_and_slide()

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
