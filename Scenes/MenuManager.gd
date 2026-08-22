extends Node2D

@onready var mouse_tooltip: Label = $Camera2D/MouseTooltip
var textTip = " "

func _ready() -> void:
	mouse_tooltip.text = textTip


func _process(_delta: float) -> void:
	mouse_tooltip.text = textTip

func _on_play_button_mouse_entered() -> void:
	textTip = "Play?"

func _on_play_button_mouse_exited() -> void:
	textTip = " "


func _on_quit_button_mouse_entered() -> void:
	textTip = "Quit?"

func _on_quit_button_mouse_exited() -> void:
	textTip = " "

func _on_quit_button_pressed() -> void:
	get_tree().quit()
