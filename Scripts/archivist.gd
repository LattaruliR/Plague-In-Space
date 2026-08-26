extends CanvasLayer

const ALERT_SOUND := preload("res://SOUNDS/barTone.wav")
const TONE_SOUND := preload("res://SOUNDS/barTone2.wav")
const FONT := preload("res://Fonts/home-video/HomeVideo-Regular.ttf")

const CONTAINMENT_DRAIN := 1.6
const CONTAINMENT_WIND := 9.0
const BLACKOUT_DRAIN_MULT := 0.7
const ESCAPE_WINDOW := 12.0
const CRITICAL_THRESHOLD := 25.0

signal broke_loose
signal contained_again
signal survived_escape

var containment := 100.0
var loose := false
var escape_left := 0.0
var winding := false

var _armed := false
var _was_critical := false
var _cue_elapsed := 0.0

var _root: Control
var _bar: ProgressBar
var _label: Label


func _ready() -> void:
	layer = 22
	_build_ui()
	visible = false

func arm() -> void:
	_armed = true
	containment = 100.0
	loose = false
	escape_left = 0.0
	winding = false
	_was_critical = false
	visible = true


func reset() -> void:
	_armed = false
	loose = false
	winding = false
	containment = 100.0
	escape_left = 0.0
	visible = false

func set_winding(active: bool) -> void:
	winding = active and Global.player_room == Global.Room.COMMS_SYS


func _process(delta: float) -> void:
	if not _armed:
		visible = false
		return
	visible = true

	if loose:
		_tick_escape(delta)
	else:
		_tick_containment(delta)

	_refresh_ui()


func _tick_containment(delta: float) -> void:
	if winding and Global.player_room == Global.Room.COMMS_SYS:
		containment = minf(containment + CONTAINMENT_WIND * delta, 100.0)
	else:
		var drain := CONTAINMENT_DRAIN
		if Global.blackout:
			drain *= BLACKOUT_DRAIN_MULT
		containment = maxf(containment - drain * delta, 0.0)

	var critical := containment <= CRITICAL_THRESHOLD
	if critical and not _was_critical:
		AudioManager.play_sfx(ALERT_SOUND, -4.0, 0.5)
	_was_critical = critical

	if containment <= 0.0:
		_break_loose()


func _break_loose() -> void:
	loose = true
	winding = false
	escape_left = ESCAPE_WINDOW
	_cue_elapsed = 0.0
	AudioManager.play_sfx(ALERT_SOUND, 2.0, 0.2)
	broke_loose.emit()

func _is_safe() -> bool:
	return Global.hiding and Global.player_room == Global.Room.PLAYER_ROOM


func _tick_escape(delta: float) -> void:
	if _is_safe():
		_survive()
		return

	_cue_elapsed += delta
	if _cue_elapsed >= 1.0:
		_cue_elapsed = 0.0
		AudioManager.play_sfx(ALERT_SOUND, -2.0, 0.3)

	escape_left -= delta
	if escape_left <= 0.0:
		_catch()


func _survive() -> void:
	loose = false
	escape_left = 0.0
	containment = 100.0
	_was_critical = false
	AudioManager.play_sfx(TONE_SOUND, -4.0, 1.2)
	survived_escape.emit()
	contained_again.emit()


func _catch() -> void:
	loose = false
	_armed = false
	Global.hiding = false
	Global.hide_side = -1
	GameOver.record_cause("THE ARCHIVE OPENED")
	Global.infection_value = 100.0
	Global.panic = true
	AudioManager.play_sfx(ALERT_SOUND, 2.0, 0.15)

func _refresh_ui() -> void:
	if loose:
		_bar.value = 0.0
		_bar.modulate = TerminalStyle.RED
		_label.text = "IT IS OUT - HIDE IN THE OFFICE   %.0f" % maxf(escape_left, 0.0)
		_label.add_theme_color_override("font_color", TerminalStyle.RED)
		return

	_bar.value = containment
	if containment <= CRITICAL_THRESHOLD:
		_bar.modulate = TerminalStyle.RED
		_label.text = "CONTAINMENT FAILING - CRANK IT IN COMMS"
		_label.add_theme_color_override("font_color", TerminalStyle.RED)
	elif containment <= 60.0:
		_bar.modulate = TerminalStyle.AMBER
		_label.text = "CONTAINMENT %d%%" % int(containment)
		_label.add_theme_color_override("font_color", TerminalStyle.AMBER)
	else:
		_bar.modulate = TerminalStyle.GREEN
		_label.text = "CONTAINMENT %d%%" % int(containment)
		_label.add_theme_color_override("font_color", TerminalStyle.GREEN)


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_root.offset_top = 12
	_root.offset_bottom = 74
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.custom_minimum_size = Vector2(420, 0)
	column.add_theme_constant_override("separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(column)

	_label = Label.new()
	_label.add_theme_font_override("font", FONT)
	_label.add_theme_font_size_override("font_size", 20)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.visible = false
	column.add_child(_label)

	_bar = ProgressBar.new()
	_bar.min_value = 0.0
	_bar.max_value = 100.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 14)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.visible = false
	column.add_child(_bar)
