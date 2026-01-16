## ArcherLaserBeam - Visual effect cho special attack của Archer
## Hiển thị laser beam mà không bắn đi như projectile
## Player sẽ dùng hitbox để gây damage, laser chỉ là visual
extends Line2D

@export var beam_length: float = 500.0  # Độ dài laser
@export var beam_width: float = 8.0  # Độ rộng ban đầu
@export var beam_duration: float = 0.5  # Thời gian hiển thị
@export var fade_duration: float = 0.3  # Thời gian fade out

var time_elapsed: float = 0.0
var initial_color: Color = Color(0.2, 1.0, 0.8, 1.0)  # Cyan-green color

func _ready() -> void:
	# Setup line appearance
	width = beam_width
	default_color = initial_color
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND
	
	# Set points (từ 0,0 đến beam_length theo hướng phải)
	clear_points()
	add_point(Vector2.ZERO)
	add_point(Vector2(beam_length, 0))
	
	# Add glow effect với gradient
	var beam_gradient = Gradient.new()
	beam_gradient.add_point(0.0, Color(0.2, 1.0, 0.8, 0.3))
	beam_gradient.add_point(0.5, Color(0.2, 1.0, 0.8, 1.0))
	beam_gradient.add_point(1.0, Color(0.2, 1.0, 0.8, 0.3))
	# Note: gradient chỉ dùng nếu có texture, nếu không sẽ dùng default_color

func _process(delta: float) -> void:
	time_elapsed += delta
	
	# Fade out effect
	if time_elapsed >= beam_duration:
		var fade_progress = (time_elapsed - beam_duration) / fade_duration
		fade_progress = clamp(fade_progress, 0.0, 1.0)
		
		# Reduce opacity
		var color = initial_color
		color.a = 1.0 - fade_progress
		default_color = color
		
		# Reduce width
		width = beam_width * (1.0 - fade_progress)
		
		# Destroy when fully faded
		if fade_progress >= 1.0:
			queue_free()

## Flip laser theo direction của player
func set_direction(dir: float) -> void:
	if dir < 0:
		# Flip laser sang trái
		clear_points()
		add_point(Vector2.ZERO)
		add_point(Vector2(-beam_length, 0))
