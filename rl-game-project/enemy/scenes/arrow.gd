extends AnimatedSprite2D

var speed: int = 300
var direction: int
@onready var hitbox: Hitbox = $Area2D

func _ready() -> void:
	hitbox.enable()

func _physics_process(delta: float) -> void:
	move_local_x(direction * speed * delta)

func _on_timer_timeout() -> void:
	queue_free()
