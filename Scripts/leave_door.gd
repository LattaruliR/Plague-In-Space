extends Button

func _ready() -> void:
	if not pressed.is_connected(Rooms.open_travel_menu):
		pressed.connect(Rooms.open_travel_menu)
