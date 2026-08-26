extends Node2D

@export var button: Button
@export var label: Label
@onready var laugh_timer: Timer = $"../laughTimer"
var laughing := true

func laugh():
	$"../../../AUDIO/GopherLaughs".play()

func _process(_delta: float) -> void:
	var held: bool = button != null and button.button_pressed
	Archivist.set_winding(held)

	

	if label != null:
		if Archivist.winding:
			label.text = "WINDING"
		else:
			label.text = "CONTAINMENT %d%%" % int(Archivist.containment)
	
	if Archivist.winding && laughing == true:
		laughing = false
		laugh_timer.start()
		laugh()


func _on_laugh_timer_timeout() -> void:
	laughing = true
