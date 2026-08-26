extends AnimatedSprite2D




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if int(Archivist.containment) == 20:
		frame = 5
	elif int(Archivist.containment) == 30:
		frame = 4
	elif int(Archivist.containment) == 40:
		frame = 3
	elif int(Archivist.containment) == 50:
		frame = 2
	elif int(Archivist.containment) == 70:
		frame = 1
	elif int(Archivist.containment) == 100:
		frame = 0
