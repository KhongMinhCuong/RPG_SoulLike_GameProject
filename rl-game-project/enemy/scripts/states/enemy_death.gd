extends State
class_name EnemyDeath

var monster: EnemyBase
var hurtbox: Hurtbox

func enter():
	monster = owner as EnemyBase
	if monster == null:
		monster = get_parent().owner as EnemyBase
	
	hurtbox = monster.get_node("Hurtbox")
	hurtbox.disable()
		
	print("DEATH")
	owner.animated_sprite.play("death")
	owner.animated_sprite.connect("animation_finished", Callable(self, "_finished"))

func _finished():
	owner.queue_free()
