extends ColorRect

@onready var manual_1_label: Label = $Manual1Label
@onready var manual_2_label: Label = $Manual2Label
@onready var manual_3_label: Label = $Manual3Label




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	manual_1_label.text = "Nothing"
