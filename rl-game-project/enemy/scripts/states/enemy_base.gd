extends CharacterBody2D
class_name EnemyBase

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var damage: float = 10
@export var detection_range: float = 250.0
@export var stop_distance: float = 30
@export var attack_cooldown: float = 1.2
@export var attack_range: float = 65.0
@export var wait_time_range := Vector2(1.0, 2.0)
@export var max_health: float = 100
@export var move_speed: float = 20
@export var chase_speed: float = 40 
@export var gravity: float = 900.0
@export var chase_range: float = 250.0

var stun_duration := 0
var is_parry_stun := false

var direction: int
var health: float
var player: CharacterBody2D = null

func _enter_tree():
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
	else:
		push_warning("No player found in group 'Player' at enter_tree()")

func _ready():
	health = max_health


func _physics_process(delta):
	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	move_and_slide();

# khi bị tấn công thường thì is_parry là false
# bị parry thì gọi với is_parry là true
func take_damage(damage, is_parry := false):
	health -= damage
	is_parry_stun = is_parry
	print("Enemy hit! HP:", health)
	
	# overide mọi state
	var sm = get_node("StateMachine")
	sm.on_child_transition(sm.current_state, "EnemyHurtstun")
