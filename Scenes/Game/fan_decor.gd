extends AnimatedSprite2D

var stopped = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Global.blackout == true && stopped == false:
		var tween = create_tween()
		tween.tween_property(self, "speed_scale", 0, 1)
		stopped = true
	else:
		speed_scale = 1.23
		stopped = false
		play("spinning")
