extends Node2D

@export var button: Button
@export var label: Label

func _process(_delta: float) -> void:
	var held: bool = button != null and button.button_pressed
	Archivist.set_winding(held)

	if label != null:
		if Archivist.winding:
			label.text = "WINDING"
		else:
			label.text = "CONTAINMENT %d%%" % int(Archivist.containment)
