extends State
class_name EnemyDeath

func enter():
	print("DEATH")
	owner.animated_sprite.play("death")
	owner.animated_sprite.connect("animation_finished", Callable(self, "_finished"))

func _finished():
	owner.queue_free()
