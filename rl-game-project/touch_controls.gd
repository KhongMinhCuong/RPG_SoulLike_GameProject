class_name TouchControls
extends CanvasLayer

# Signals for button presses
signal attack_pressed
signal dash_pressed
signal parry_pressed
signal sp_atk_pressed
signal unique_pressed

@onready var atk_button : TouchScreenButton = $AtkButton
@onready var dash_button : TouchScreenButton = $DashButton
@onready var parry_button : TouchScreenButton = $ParryButton
@onready var sp_atk_button : TouchScreenButton = $SpAtkButton
@onready var unique_button : TouchScreenButton = $UniqueButton

func _ready() -> void:
	# Connect button signals to emit custom signals
	if atk_button:
		atk_button.pressed.connect(_on_attack_button_pressed)
		print("AtkButton connected")
	if dash_button:
		dash_button.pressed.connect(_on_dash_button_pressed)
		print("DashButton connected")
	if parry_button:
		parry_button.pressed.connect(_on_parry_button_pressed)
		print("ParryButton connected")
	if sp_atk_button:
		sp_atk_button.pressed.connect(_on_sp_atk_button_pressed)
		print("SpAtkButton connected")
	if unique_button:
		unique_button.pressed.connect(_on_unique_button_pressed)
		print("UniqueButton connected")

func _on_attack_button_pressed() -> void:
	#print("Attack button pressed!")
	attack_pressed.emit()

func _on_dash_button_pressed() -> void:
	#print("Dash button pressed!")
	dash_pressed.emit()

func _on_parry_button_pressed() -> void:
	#print("Parry button pressed!")
	parry_pressed.emit()

func _on_sp_atk_button_pressed() -> void:
	#print("Special Attack button pressed!")
	sp_atk_pressed.emit()

func _on_unique_button_pressed() -> void:
	#print("Unique button pressed!")
	unique_pressed.emit()
