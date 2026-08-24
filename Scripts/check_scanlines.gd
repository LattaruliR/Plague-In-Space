extends Sprite2D


func _process(_delta: float) -> void:
	if Global.scanlines == false:
		hide()
	else: show()
