extends Node2D

@export var pos_positions: Array[Marker2D] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = pos_positions[0].position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	position = pos_positions.pick_random().position
