extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox

@export var max_health: float = 100
@export var move_speed: float = 400 
@export var gravity: float = 900.0
@export var jump_velocity = -400.0
@export var attack_damage: float = 20.0

var direction: int
var health: float
var attacking := false

func _ready():
	health = max_health
	hitbox.damage = attack_damage
	hitbox.disable()
	hurtbox.connect("damaged", Callable(self, "_on_damaged"))

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		
	direction = Input.get_axis("ui_left", "ui_right")
	
	if not attacking:
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	
	movement(delta)

	if Input.is_action_just_pressed("attack"):
		attack()

func movement(delta):
	if Input.is_action_pressed("ui_right"):
		velocity.x = move_speed
		animated_sprite.flip_h = false
	elif Input.is_action_pressed("ui_left"):
		velocity.x = -move_speed
		animated_sprite.flip_h = true
	else:
		velocity.x = 0
	
	move_and_slide()

func attack():
	if attacking:
		return
	attacking = true
	animated_sprite.play("attack")

	await get_tree().create_timer(0.4).timeout
	hitbox.disable()
	attacking = false

func take_damage(damage: float):
	health -= damage
	print("Player took ", damage, " damage! Health: ", health)
	if health <= 0:
		queue_free()
