extends Node2D

@export var camera_2d: Camera2D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	camera_2d.position = get_global_mouse_position()
