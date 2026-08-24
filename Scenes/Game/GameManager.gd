extends Node2D

## Sets the scene up for a run. The camera window is owned by Rooms, so point
## it at wherever the player actually is rather than trusting whatever bounds
## were last saved into the scene.

func _ready() -> void:
	Rooms.snap_to_player()
