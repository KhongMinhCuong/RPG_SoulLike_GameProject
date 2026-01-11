extends ProgressBar

var parent
var max_value_amount
var min_value_amount

func _ready():
	parent = get_parent()
	max_value_amount = parent.max_health
	min_value_amount = 0

func _process(delta):
	self.value = parent.health
	if parent.health == max_value_amount or parent.health == min_value_amount:
		self.visible = false
	else:
		self.visible = true
