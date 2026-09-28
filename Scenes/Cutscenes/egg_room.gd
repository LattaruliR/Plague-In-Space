extends Node2D
@onready var mouse_tooltip: Label = $Camera/MouseTooltip


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_tree_button_mouse_entered() -> void:
	mouse_tooltip.text = "Tree"


func _on_tree_button_mouse_exited() -> void:
	mouse_tooltip.text = ""
