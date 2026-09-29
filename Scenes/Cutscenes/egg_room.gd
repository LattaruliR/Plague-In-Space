extends Node2D

@onready var mouse_tooltip: Label = $Camera/MouseTooltip
@onready var dialogue_reader: DialogueReader = $DialogueReader

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("menu"):
		get_tree().change_scene_to_file("res://Scenes/Menu/menu.tscn")



func _on_tree_button_mouse_entered() -> void:
	if dialogue_reader.is_typing == true:
		mouse_tooltip.text = "Tree?"
	else: mouse_tooltip.text = "Tree"


func _on_tree_button_mouse_exited() -> void:
	mouse_tooltip.text = ""
