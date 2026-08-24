extends Node2D

## one of the two hiding places in the office. when the plague hunts, a cue
## plays from the left or the right; the player has to be tucked into the spot
## on that side when the window closes

const GREEN := Color(0.35, 1.0, 0.35)

## 0 for the left-hand spot, 1 for the right-hand one
@export var side: int = 0
@export var button: Button
@export var sprite: Node2D

func _ready() -> void:
	if button != null and not button.pressed.is_connected(_on_pressed):
		button.pressed.connect(_on_pressed)

	Global.player_caught.connect(_on_player_caught)
	Blackout.hunt_survived.connect(_on_hunt_survived)
	_refresh()

func _on_pressed() -> void:
	# clicking the spot you are already in climbs back out of it
	var already_here := Global.hiding and Global.hide_side == side
	Blackout.set_hiding(side, not already_here)
	_refresh()

func _on_player_caught() -> void:
	# blackout clears the hiding state itself; just redraw
	_refresh()

func _on_hunt_survived() -> void:
	_refresh()

func _refresh() -> void:
	if sprite == null:
		return
	var occupied := Global.hiding and Global.hide_side == side
	sprite.modulate = GREEN if occupied else Color.WHITE
