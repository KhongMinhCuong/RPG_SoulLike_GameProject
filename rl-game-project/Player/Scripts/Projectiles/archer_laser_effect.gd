## ArcherLaserEffect - Visual effect cho special attack của Archer
## Sử dụng AnimatedSprite2D để play sprite animation
## Player dùng hitbox để gây damage, đây chỉ là visual effect
extends Node2D

@export var effect_duration: float = 1.0  # Thời gian hiển thị effect
@export var fade_start: float = 0.7  # Bắt đầu fade ở % nào của duration

var time_elapsed: float = 0.0
var facing_direction: float = 1.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Play animation nếu có
	if animated_sprite:
		# Flip theo direction
		animated_sprite.flip_h = (facing_direction < 0)
		
		# Play animation (animation name có thể là "default", "laser", "beam", etc.)
		if animated_sprite.sprite_frames:
			var anim_names = animated_sprite.sprite_frames.get_animation_names()
			if anim_names.size() > 0:
				animated_sprite.play(anim_names[0])
		
		# Connect animation finished
		animated_sprite.animation_finished.connect(_on_animation_finished)

func _process(delta: float) -> void:
	time_elapsed += delta
	
	# Fade effect
	if time_elapsed >= effect_duration * fade_start:
		var fade_progress = (time_elapsed - effect_duration * fade_start) / (effect_duration * (1.0 - fade_start))
		fade_progress = clamp(fade_progress, 0.0, 1.0)
		modulate.a = 1.0 - fade_progress
	
	# Auto destroy sau effect_duration
	if time_elapsed >= effect_duration:
		queue_free()

func _on_animation_finished() -> void:
	# Có thể loop hoặc destroy tùy theo animation setup
	pass

## Set direction của laser (gọi trước khi add to scene)
func set_direction(dir: float) -> void:
	facing_direction = dir
	if animated_sprite:
		animated_sprite.flip_h = (dir < 0)
