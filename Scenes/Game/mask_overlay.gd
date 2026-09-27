extends Sprite2D

@onready var mask_idle: AnimationPlayer = $"../MaskIdle"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Global.hiding == true:
		show()
		mask_idle.play("idle")
	else:
		mask_idle.stop()
		hide()
