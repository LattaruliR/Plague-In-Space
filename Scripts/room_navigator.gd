extends CanvasLayer

const FONT := preload("res://Fonts/home-video/HomeVideo-Regular.ttf")
const DOOR_SOUND := preload("res://SOUNDS/selecting.wav")
const ALERT_SOUND := preload("res://SOUNDS/barTone.wav")

const VIEW_HALF_EXTENTS := Vector2(592, 339)

## The travel menu runs red rather than the usual phosphor green -- leaving the
## room is the risky move, so it should not look like a routine readout.
const ACCENT := Color(0.61, 0, 0.0824)
const PANEL_BG := Color(0, 0, 0, 1)

signal room_changed(room: int)
signal travel_refused(reason: String)

var views := {} # Global.Room -> world origin of that room

var _panel: PanelContainer
var _list: VBoxContainer
var _open := false


func _ready() -> void:
	layer = 15
	_build_views()
	_build_ui()
	visible = false


func _build_views() -> void:
	views = {
		Global.Room.PLAYER_ROOM: Vector2(-706, 778),
		Global.Room.COMMS_SYS: Vector2(671, 779),
		Global.Room.KITCHEN: Vector2(2048, 779),
	}


func _unhandled_input(event: InputEvent) -> void:
	if _open and event.is_action_pressed("ui_cancel"):
		close_travel_menu()
		get_viewport().set_input_as_handled()


func is_open() -> bool:
	return _open

func open_travel_menu() -> void:
	var blocked := _blocked_reason()
	if blocked != "":
		AudioManager.play_sfx(ALERT_SOUND, -6.0, 0.5)
		travel_refused.emit(blocked)
		return

	_rebuild_list()
	_open = true
	visible = true
	AudioManager.play_sfx(DOOR_SOUND, -6.0, 1.1)


func close_travel_menu() -> void:
	_open = false
	visible = false


func _blocked_reason() -> String:
	if Global.hunting:
		return "IT IS IN HERE WITH YOU"
	if Global.hiding:
		return "NOT WHILE YOU ARE HIDDEN"
	if Global.door_closed and Global.player_room == Global.Room.PLAYER_ROOM:
		return "THE BLAST DOOR IS SHUT"
	return ""


func _rebuild_list() -> void:
	for child in _list.get_children():
		child.queue_free()

	var header := _label("WHERE TO?", 30)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_list.add_child(header)

	for room in views:
		if room == Global.player_room:
			continue
		var button := _button(Global.ROOM_NAMES.get(room, "ROOM"))
		button.pressed.connect(_on_destination_pressed.bind(room))
		_list.add_child(button)

	var cancel := _button("STAY HERE")
	cancel.pressed.connect(close_travel_menu)
	_list.add_child(cancel)


func _on_destination_pressed(room: int) -> void:
	close_travel_menu()
	travel_to(room)

func travel_to(room: int) -> bool:
	if not views.has(room):
		return false

	var blocked := _blocked_reason()
	if blocked != "":
		travel_refused.emit(blocked)
		return false

	Global.player_room = room
	_apply_view(room)
	AudioManager.play_sfx(DOOR_SOUND, -4.0, 0.8)
	room_changed.emit(room)
	return true

func _apply_view(room: int) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var camera := scene.get_node_or_null("Camera") as Camera2D
	if camera == null:
		return

	var origin: Vector2 = views.get(room, Vector2.ZERO)
	camera.limit_left = int(origin.x - VIEW_HALF_EXTENTS.x)
	camera.limit_right = int(origin.x + VIEW_HALF_EXTENTS.x)
	camera.limit_top = int(origin.y - VIEW_HALF_EXTENTS.y)
	camera.limit_bottom = int(origin.y + VIEW_HALF_EXTENTS.y)
	camera.position = origin
	camera.reset_smoothing()

func snap_to_player() -> void:
	_apply_view(Global.player_room)

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel",
			TerminalStyle.outline_style(PANEL_BG, ACCENT))
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_panel.add_child(margin)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 12)
	margin.add_child(_list)


func _label(text: String, size: int) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", FONT)
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", ACCENT)
	return node


func _button(text: String) -> Button:
	return TerminalStyle.text_button(text, Vector2(360, 50), 28, ACCENT)
