extends Node2D

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
	position = pos_positions[_marker_index()].position

func _marker_index() -> int:
	var index := 0 if Global.player_room == Global.Room.COMMS_SYS else 1
	return clampi(index, 0, pos_positions.size() - 1)
