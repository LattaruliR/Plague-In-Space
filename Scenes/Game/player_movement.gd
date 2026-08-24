extends Node2D

## The player's token on the ship map. It follows Global.player_room rather
## than moving on its own, so the Plague, the cameras and the map always agree
## on where the player actually is.
##
## Markers are in Global.Room order: Kitchen, Power Grid, Heat, Oxygen, Comms,
## Player Room.
@export var pos_positions: Array[Marker2D] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_snap_to_room()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_snap_to_room()

func _snap_to_room() -> void:
	if pos_positions.is_empty():
		return
	position = pos_positions[clampi(Global.player_room, 0, pos_positions.size() - 1)].position
