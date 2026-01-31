extends ProgressBar

var parent

func _ready():
	parent = get_parent()
	self.min_value = 0
	self.max_value = parent.max_health

func _process(delta):
	self.value = parent.health
	if parent.health >= parent.max_health or parent.health <= 0:
		self.visible = false
	else:
		self.visible = true
