extends CanvasLayer

const FONT := preload("res://Fonts/home-video/HomeVideo-Regular.ttf")
const CLICK_SOUND := preload("res://SOUNDS/selecting.wav")
const ALERT_SOUND := preload("res://SOUNDS/barTone.wav")

const RED := TerminalStyle.RED
const AMBER := TerminalStyle.AMBER

enum Mode { CAMERAS, OXYGEN, HEAT }

## rooms shown on the camera feed, in ship order.
const CAMERA_ROOMS := [0, 1, 2, 3, 4, 5] # Global.Room values

var mode: int = Mode.CAMERAS
var is_open := false

var _root: Control
var _tab_buttons := {}
var _pages := {}

var _camera_rows := []
var _lure_status: Label

var _oxygen_bar: ProgressBar
var _oxygen_text: Label
var _heat_bar: ProgressBar
var _heat_text: Label

var _offline_label: Label


func _ready() -> void:
	
	layer = -1
	_build_ui()
	visible = false

	Rooms.room_changed.connect(_on_room_changed)


func _process(_delta: float) -> void:
	if not is_open:
		return

	var offline := Global.blackout
	_offline_label.visible = offline
	for key in _pages:
		_pages[key].visible = (not offline) and key == mode
	for key in _tab_buttons:
		_tab_buttons[key].disabled = offline or key == mode
	if offline:
		return

	match mode:
		Mode.CAMERAS:
			_refresh_cameras()
		Mode.OXYGEN:
			_refresh_oxygen()
		Mode.HEAT:
			_refresh_heat()

func _unhandled_input(event: InputEvent) -> void:
	if is_open and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if Global.player_room != Global.Room.PLAYER_ROOM:
		return # the computer is bolted to the office desk
	is_open = false
	visible = false
	_set_mode(mode)
	AudioManager.play_sfx(CLICK_SOUND, -6.0, 1.2)


func close() -> void:
	is_open = false
	visible = false
	AudioManager.play_sfx(CLICK_SOUND, -8.0, 0.9)


func _on_room_changed(room: int) -> void:
	if room != Global.Room.PLAYER_ROOM and is_open:
		close()


func _set_mode(new_mode: int) -> void:
	mode = new_mode
	for key in _pages:
		_pages[key].visible = key == mode
	for key in _tab_buttons:
		_tab_buttons[key].disabled = key == mode
	AudioManager.play_sfx(CLICK_SOUND, -8.0, 1.0)

func _refresh_cameras() -> void:
	var plague := Blackout.get_plague()
	var plague_room: int = plague.cur_position if plague != null else -1
	var lure_target: int = plague.lure_target if plague != null else -1

	var neighbours_of_player: Array = []
	if plague != null:
		neighbours_of_player = plague.NEIGHBOURS.get(Global.player_room, [])

	for row in _camera_rows:
		var room: int = row["room"]
		var status := "CLEAR"
		var colour := TerminalStyle.GREEN

		if CoreResources.is_sabotaged(room):
			status = "SABOTAGED"
			colour = AMBER

		if room == plague_room:
			status = "*** CONTACT ***"
			colour = RED
		elif room == Global.player_room:
			status = "YOU"
			colour = TerminalStyle.GREEN
		elif room == lure_target:
			status = "LURE ACTIVE"
			colour = AMBER

		if room == plague_room and neighbours_of_player.has(room):
			status = "*** APPROACHING ***"

		row["status"].text = status
		row["status"].add_theme_color_override("font_color", colour)
		row["name"].add_theme_color_override("font_color", colour)

		var can_lure_here: bool = plague != null and plague.can_lure() and room != plague_room
		row["lure"].disabled = not can_lure_here

	if plague == null:
		return

	if plague.lure_cooldown_left > 0.0:
		_lure_status.text = "SPEAKERS RECHARGING - %ds" % int(ceil(plague.lure_cooldown_left))
		_lure_status.add_theme_color_override("font_color", AMBER)
	else:
		_lure_status.text = "SPEAKERS READY   -   LURES UNSEEN: %d" % Global.lure_streak
		_lure_status.add_theme_color_override("font_color", TerminalStyle.GREEN)


func _on_lure_pressed(room: int) -> void:
	var plague := Blackout.get_plague()
	if plague == null:
		return
	if not plague.play_lure(room):
		AudioManager.play_sfx(ALERT_SOUND, -8.0, 0.5)

func _refresh_oxygen() -> void:
	_oxygen_bar.value = CoreResources.oxygen

	var zone := "SAFE"
	var colour := TerminalStyle.GREEN
	match CoreResources.current_oxygen_zone:
		1:
			zone = "DRY"
			colour = AMBER
		2:
			zone = "DANGER"
			colour = RED

	_oxygen_bar.modulate = colour
	var text := "%.1f%%   [%s]" % [CoreResources.oxygen, zone]
	if CoreResources.is_sabotaged(Global.Room.OXYGEN_SYS):
		text += "\nSCRUBBER SABOTAGED - REBOOT OXYGEN"
	_oxygen_text.text = text
	_oxygen_text.add_theme_color_override("font_color", colour)


func _refresh_heat() -> void:
	_heat_bar.value = CoreResources.heat

	var zone := "PERFECT"
	var colour := TerminalStyle.GREEN
	match CoreResources.current_heat_zone:
		0:
			zone = "HOT"
			colour = AMBER
		2:
			zone = "CHILLY"
			colour = Color(0.4, 0.8, 1.0)
		3:
			zone = "DANGER"
			colour = AMBER
		4:
			zone = "DEATH"
			colour = RED

	_heat_bar.modulate = colour
	var text := "%.1f%%   [%s]" % [CoreResources.heat, zone]
	if CoreResources.is_sabotaged(Global.Room.HEAT_SYS):
		text += "\nEXCHANGER SABOTAGED - REBOOT HEAT"
	_heat_text.text = text
	_heat_text.add_theme_color_override("font_color", colour)

func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.offset_left = 90
	_root.offset_right = -90
	_root.offset_top = 50
	_root.offset_bottom = -50
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(column)

	column.add_child(_build_tab_bar())

	var body := PanelContainer.new()
	body.add_theme_stylebox_override("panel",
			TerminalStyle.outline_style(Color(0.02, 0.05, 0.02, 0.96), TerminalStyle.GREEN))
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)

	var stack := MarginContainer.new()
	stack.add_theme_constant_override("margin_left", 22)
	stack.add_theme_constant_override("margin_right", 22)
	stack.add_theme_constant_override("margin_top", 18)
	stack.add_theme_constant_override("margin_bottom", 18)
	body.add_child(stack)

	_offline_label = _label("NO POWER", 48)
	_offline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_offline_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_offline_label.add_theme_color_override("font_color", TerminalStyle.AMBER)
	_offline_label.visible = false
	stack.add_child(_offline_label)

	_pages[Mode.CAMERAS] = _build_cameras_page()
	_pages[Mode.OXYGEN] = _build_gauge_page(Mode.OXYGEN)
	_pages[Mode.HEAT] = _build_gauge_page(Mode.HEAT)
	for key in _pages:
		stack.add_child(_pages[key])


func _build_tab_bar() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var title := _label("OFFICE TERMINAL", 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)

	var tabs := {
		Mode.CAMERAS: "CAMERAS",
		Mode.OXYGEN: "OXYGEN",
		Mode.HEAT: "HEAT",
	}
	for key in tabs:
		var button := TerminalStyle.text_button(tabs[key], Vector2(180, 46), 26)
		button.pressed.connect(_set_mode.bind(key))
		_tab_buttons[key] = button
		row.add_child(button)

	var close_button := TerminalStyle.text_button("CLOSE", Vector2(140, 46), 26)
	close_button.pressed.connect(close)
	row.add_child(close_button)

	return row


func _build_cameras_page() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	column.add_child(header)

	var caption := _label("SHIP CAMERAS", 26)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(caption)

	_lure_status = _label("", 22)
	header.add_child(_lure_status)

	for room in CAMERA_ROOMS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		column.add_child(row)

		var name_label := _label(Global.ROOM_NAMES.get(room, "ROOM"), 24)
		name_label.custom_minimum_size = Vector2(360, 0)
		row.add_child(name_label)

		var status := _label("CLEAR", 24)
		status.custom_minimum_size = Vector2(340, 0)
		row.add_child(status)

		var lure := TerminalStyle.text_button("LURE", Vector2(150, 40), 24)
		lure.pressed.connect(_on_lure_pressed.bind(room))
		row.add_child(lure)

		_camera_rows.append({"room": room, "name": name_label, "status": status, "lure": lure})

	var hint := _label(
		"A lure pulls it toward that room. Every lure it falls for while it has\n"
		+ "not seen you makes the next security breach more likely.", 20)
	hint.add_theme_color_override("font_color", TerminalStyle.DIM_GREEN)
	column.add_child(hint)

	return column


func _build_gauge_page(which: int) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	column.alignment = BoxContainer.ALIGNMENT_CENTER

	var caption := _label("OXYGEN" if which == Mode.OXYGEN else "HEAT", 34)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(caption)

	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.step = 0.1
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 46)
	column.add_child(bar)

	var text := _label("", 28)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(text)

	if which == Mode.OXYGEN:
		_oxygen_bar = bar
		_oxygen_text = text
	else:
		_heat_bar = bar
		_heat_text = text

	return column


func _label(text: String, size: int) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", FONT)
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", TerminalStyle.GREEN)
	return node
