extends AnimatedSprite2D

var speed: int = 300
var direction: int
@onready var hitbox: Hitbox = $Hitbox

func _ready() -> void:
	if direction < 0:
		flip_h = true
		offset *= -1
	else:
		flip_h = false
	
	hitbox.enable()

func _physics_process(delta: float) -> void:
	move_local_x(direction * speed * delta)

func _on_timer_timeout() -> void:
	queue_free()
