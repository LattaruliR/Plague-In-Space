extends Node2D
class_name  Comms_Terminal

const PRESS_SOUND := preload("res://SOUNDS/selecting.wav")
const BROADCAST_SOUND := preload("res://SOUNDS/barTone2.wav")
const ALERT_SOUND := preload("res://SOUNDS/barTone.wav")

## the broadcast repeats on this period, showing itself for the stages window
@export var broadcast_period: float = 8.0
@export var visible_time_per_stage: Array[float] = [2.0, 1.5, 1.1]
@export var download_time: float = 15.0
@export var download_extra_per_stage: float = 5.0
@export var reroll_on_failure: bool = false

@export_range(0.2, 1.5, 0.01) var ui_scale: float = 0.42
@export var ui_offset: Vector2 = Vector2(128, -70)

const PANEL_SIZE := Vector2(920, 560)

enum State { LISTENING, DOWNLOADING, COMPLETE, OFFLINE }

var state: int = State.LISTENING
var _input_sequence: Array[int] = []
var _broadcast_time: float = 0.0
var _broadcast_showing: bool = false
var _download_progress: float = 0.0

var _root: Control
var _broadcast_slots: Array[Glyph] = []
var _input_slots: Array[Glyph] = []
var _keypad_buttons: Array[Button] = []
var _reset_button: Button
var _submit_button: Button
var _status_label: Label
var _download_bar: ProgressBar


func _ready() -> void:
	_build_ui()
	CoreResources.roll_communication_combo()
	if CoreResources.recipes.is_empty():
		CoreResources.roll_recipes()
	_refresh_state()


func _process(delta: float) -> void:
	CoreResources.comms_downloading = state == State.DOWNLOADING

	if Global.blackout or CoreResources.is_sabotaged(Global.Room.COMMS_SYS):
		if state != State.OFFLINE:
			_abort_for_blackout()
		return
	elif state == State.OFFLINE:
		if CoreResources.comms_stage < CoreResources.MANUAL_COUNT:
			state = State.LISTENING
		else:
			state = State.COMPLETE
		_refresh_state()

	match state:
		State.LISTENING:
			_tick_broadcast(delta)
		State.DOWNLOADING:
			_tick_download(delta)

func _tick_broadcast(delta: float) -> void:
	_broadcast_time += delta
	if _broadcast_time >= broadcast_period:
		_broadcast_time -= broadcast_period

	var should_show := _broadcast_time < _current_visible_time()
	if should_show != _broadcast_showing:
		_broadcast_showing = should_show
		_apply_broadcast_visibility()
		if should_show:
			AudioManager.play_sfx(BROADCAST_SOUND, -6.0, 1.4)


func _current_visible_time() -> float:
	if visible_time_per_stage.is_empty():
		return 2.0
	var stage: int = clampi(CoreResources.comms_stage, 0, visible_time_per_stage.size() - 1)
	return visible_time_per_stage[stage]


func _apply_broadcast_visibility() -> void:
	var combo := CoreResources.communication_combo
	for i in _broadcast_slots.size():
		var slot := _broadcast_slots[i]
		if _broadcast_showing and i < combo.size():
			slot.glyph_index = combo[i]
		else:
			slot.glyph_index = -1

func current_download_time() -> float:
	return download_time + download_extra_per_stage * float(CoreResources.comms_stage)


func _tick_download(delta: float) -> void:
	_download_progress += delta / maxf(current_download_time(), 0.01)
	_download_bar.value = clampf(_download_progress * 100.0, 0.0, 100.0)
	_status_label.text = "DOWNLOADING MANUAL %d/%d ... %d%%" % [
		CoreResources.comms_stage + 1, CoreResources.MANUAL_COUNT, int(_download_bar.value)
	]

	if _download_progress >= 1.0:
		CoreResources.complete_manual_download()
		_download_progress = 0.0

		if CoreResources.comms_stage >= CoreResources.MANUAL_COUNT:
			state = State.COMPLETE
		else:
			state = State.LISTENING
			CoreResources.roll_communication_combo()
			_reset_broadcast()
		_refresh_state()


func _abort_for_blackout() -> void:
	state = State.OFFLINE
	_download_progress = 0.0
	_input_sequence.clear()
	_reset_broadcast()
	_refresh_state()


func _reset_broadcast() -> void:
	_broadcast_time = 0.0
	_broadcast_showing = false
	_apply_broadcast_visibility()

func _on_glyph_pressed(index: int) -> void:
	if state != State.LISTENING:
		return
	if _input_sequence.size() >= CoreResources.COMMS_SEQUENCE_LENGTH:
		return

	_input_sequence.append(index)
	AudioManager.play_sfx(PRESS_SOUND, -4.0, 1.0 + 0.08 * index)
	_refresh_input_display()


func _on_reset_pressed() -> void:
	if state != State.LISTENING:
		return
	_input_sequence.clear()
	AudioManager.play_sfx(PRESS_SOUND, -4.0, 0.7)
	_refresh_input_display()


func _on_submit_pressed() -> void:
	if state != State.LISTENING:
		return
	if _input_sequence.size() < CoreResources.COMMS_SEQUENCE_LENGTH:
		_status_label.text = "SEQUENCE INCOMPLETE"
		AudioManager.play_sfx(ALERT_SOUND, -6.0, 0.6)
		return

	if CoreResources.check_communication_combo(_input_sequence):
		if not CoreResources.can_afford_download():
			_input_sequence.clear()
			AudioManager.play_sfx(ALERT_SOUND, -4.0, 0.5)
			_refresh_input_display()
			_refresh_state()
			_status_label.text = "CODE ACCEPTED - NOT ENOUGH POWER TO PULL IT"
			return

		CoreResources.deplete_charge(CoreResources.DOWNLOAD_CHARGE_COST)
		state = State.DOWNLOADING
		_download_progress = 0.0
		_input_sequence.clear()
		_reset_broadcast()
		AudioManager.play_sfx(ALERT_SOUND, -2.0, 1.5)
		_refresh_input_display()
		_refresh_state()
	else:
		_input_sequence.clear()
		AudioManager.play_sfx(ALERT_SOUND, -2.0, 0.5)
		if reroll_on_failure:
			CoreResources.roll_communication_combo()
			_reset_broadcast()
		_refresh_input_display()
		_refresh_state()
		_status_label.text = "SIGNAL REJECTED - RETRY"

func _refresh_state() -> void:
	var interactive := state == State.LISTENING
	for button in _keypad_buttons:
		button.disabled = not interactive
	_reset_button.disabled = not interactive
	_submit_button.disabled = not interactive

	_download_bar.visible = state == State.DOWNLOADING
	_download_bar.value = clampf(_download_progress * 100.0, 0.0, 100.0)

	match state:
		State.LISTENING:
			_status_label.text = "MANUALS: %d/%d - AWAITING BROADCAST" % [
				CoreResources.comms_stage, CoreResources.MANUAL_COUNT
			]
		State.DOWNLOADING:
			_status_label.text = "DOWNLOADING MANUAL %d/%d ..." % [
				CoreResources.comms_stage + 1, CoreResources.MANUAL_COUNT
			]
		State.COMPLETE:
			_status_label.text = "ALL MANUALS RECEIVED - CHECK THE KITCHEN"
		State.OFFLINE:
			if CoreResources.is_sabotaged(Global.Room.COMMS_SYS):
				_status_label.text = "ARRAY SABOTAGED - REBOOT COMMS IN THE OFFICE"
			else:
				_status_label.text = "NO POWER - TERMINAL OFFLINE"

	if state == State.OFFLINE:
		_root.modulate = Color(0.4, 0.4, 0.4)
	else:
		_root.modulate = Color.WHITE

	_refresh_input_display()


func _refresh_input_display() -> void:
	for i in _input_slots.size():
		if i < _input_sequence.size():
			_input_slots[i].glyph_index = _input_sequence[i]
		else:
			_input_slots[i].glyph_index = -1

func _build_ui() -> void:
	_root = Control.new()
	_root.size = PANEL_SIZE
	_root.scale = Vector2(ui_scale, ui_scale)
	_root.position = -PANEL_SIZE * 0.5 * ui_scale + ui_offset
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(column)

	column.add_child(_build_broadcast_panel())
	column.add_child(_build_keypad_panel())
	column.add_child(_build_readout_panel())

	_download_bar = ProgressBar.new()
	_download_bar.min_value = 0.0
	_download_bar.max_value = 100.0
	_download_bar.custom_minimum_size = Vector2(0, 22)
	_download_bar.show_percentage = false
	_download_bar.modulate = TerminalStyle.GREEN
	_download_bar.visible = false
	column.add_child(_download_bar)

	_status_label = TerminalStyle.label("", 26)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_status_label)


func _build_broadcast_panel() -> Control:
	var panel := TerminalStyle.panel()

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	TerminalStyle.wrap_in_margin(panel, box, 14)

	var title := TerminalStyle.label(TerminalStyle.spaced("COMMUNICATION ATLAS V2"), 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	box.add_child(row)

	for i in CoreResources.COMMS_SEQUENCE_LENGTH:
		var glyph := Glyph.create(-1, Vector2(72, 72), 2.5)
		_broadcast_slots.append(glyph)
		row.add_child(glyph)

	return panel


func _build_keypad_panel() -> Control:
	var panel := TerminalStyle.panel()

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	TerminalStyle.wrap_in_margin(panel, row, 16)

	for i in CoreResources.COMMS_SYMBOL_COUNT:
		var button := _make_glyph_button(i)
		_keypad_buttons.append(button)
		row.add_child(button)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(24, 0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)

	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	row.add_child(actions)

	_reset_button = TerminalStyle.text_button("RESET")
	_reset_button.pressed.connect(_on_reset_pressed)
	actions.add_child(_reset_button)

	_submit_button = TerminalStyle.text_button("SUBMIT")
	_submit_button.pressed.connect(_on_submit_pressed)	
	actions.add_child(_submit_button)

	return panel


func _build_readout_panel() -> Control:
	var panel := TerminalStyle.panel()

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	TerminalStyle.wrap_in_margin(panel, row, 12)

	var caption := TerminalStyle.label("Current\nSequence\nInputed:", 24)
	caption.custom_minimum_size = Vector2(190, 0)
	row.add_child(caption)

	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 18)
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	slots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(slots)

	for i in CoreResources.COMMS_SEQUENCE_LENGTH:
		var glyph := Glyph.create(-1, Vector2(56, 56), 2.0)
		glyph.show_empty_slot = true
		_input_slots.append(glyph)
		slots.add_child(glyph)

	return panel


func _make_glyph_button(index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(104, 104)
	TerminalStyle.style_button(button)
	button.pressed.connect(_on_glyph_pressed.bind(index))

	var glyph := Glyph.create(index, Vector2.ZERO, 2.5)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glyph.offset_left = 16
	glyph.offset_top = 16
	glyph.offset_right = -16
	glyph.offset_bottom = -16
	button.add_child(glyph)

	return button
