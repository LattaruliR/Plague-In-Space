extends Node2D

const WIND_SECONDS := 7.0
const CLICK_SOUND := preload("res://SOUNDS/selecting.wav")
const DONE_SOUND := preload("res://SOUNDS/barTone2.wav")

@export var button: Button
@export var label: Label

var _held := 0.0

func _ready() -> void:
	if button != null:
		button.button_down.connect(func(): _held = 0.0)

func _process(delta: float) -> void:
	var holding: bool = button != null and button.button_pressed \
			and Global.player_room == Global.Room.PLAYER_ROOM

	if holding and Global.panic:
		_held += delta
		if _held >= WIND_SECONDS:
			_held = 0.0
			Global.panic = false
			AudioManager.play_sfx(DONE_SOUND, -2.0, 1.4)
	elif not holding:
		_held = maxf(_held - delta * 2.0, 0.0)

	if label == null:
		return

	if not Global.panic:
		label.text = "CALM"
		label.add_theme_color_override("font_color", TerminalStyle.GREEN)
	elif _held > 0.0:
		label.text = "WINDING %d%%" % int(_held / WIND_SECONDS * 100.0)
		label.add_theme_color_override("font_color", TerminalStyle.AMBER)
	else:
		label.text = "PANIC - HOLD TO WIND"
		label.add_theme_color_override("font_color", TerminalStyle.RED)
