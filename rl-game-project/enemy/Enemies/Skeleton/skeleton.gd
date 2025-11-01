extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var speed = 3000.0
@export var patrol_points : Node
@onready var timer: Timer = $Timer

var player_chase = false
var player = null

enum state {idle, walk, attack, death}
var current_state = state
var direction : Vector2 = Vector2.LEFT
var number_of_point : int
var point_position : Array[Vector2]
var current_point : Vector2
var current_point_position : int
var can_walk : bool

func _ready():
	if patrol_points != null:
		number_of_point = patrol_points.get_children().size()
		for point in patrol_points.get_children():
			point_position.append(point.global_position)
		current_point = point_position[current_point_position]
	else:
		print("No patrol point")
	
	current_state = state.idle
		

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	idle_state(delta)
	walk_state(delta)
	
	move_and_slide()
	
	enemy_animation()

func idle_state(delta : float):
	if !can_walk:
		velocity.x = move_toward(velocity.x, 0, speed * delta)
		current_state = state.idle

func walk_state(delta :float):
	if !can_walk:
		return
	
	if abs(position.x - current_point.x) > 0.5:
		velocity.x = direction.x * speed * delta
		current_state = state.walk
	else:
		current_point_position +=1
		
		if current_point_position >= number_of_point:
			current_point_position = 0
		
		current_point = point_position[current_point_position]
		
		if current_point.x > position.x:
			direction = Vector2.RIGHT
		else:
			direction = Vector2.LEFT
			
		can_walk = false
		timer.start()

	animated_sprite.flip_h = direction.x < 0
	
func enemy_animation():
	if current_state == state.idle && !can_walk:
		animated_sprite.play("idle")
	elif current_state == state.walk:
		animated_sprite.play("walk")

func _on_detection_area_body_entered(body: Node2D) -> void:
	player = body
	player_chase = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	player = null
	player_chase = false


func _on_timer_timeout() -> void:
	can_walk = true
