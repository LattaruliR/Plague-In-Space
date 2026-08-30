extends CanvasLayer

const FONT := preload("res://Fonts/home-video/HomeVideo-Regular.ttf")
const CLICK_SOUND := preload("res://SOUNDS/selecting.wav")

const ACCENT := Color(0.61, 0, 0.0824)

var is_open := false

var _list: VBoxContainer
var _counter: Label
var _empty_note: Label


func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false


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
	_rebuild()
	is_open = true
	visible = true
	AudioManager.play_sfx(CLICK_SOUND, -6.0, 1.1)


func close() -> void:
	is_open = false
	visible = false
	AudioManager.play_sfx(CLICK_SOUND, -8.0, 0.9)


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()

	var defs := Achievements.all_defs()
	_counter.text = "%d / %d UNLOCKED" % [Achievements.unlocked_count(), defs.size()]
	_empty_note.visible = defs.is_empty()

	for def in defs:
		var card := AchievementCard.build(FONT)
		AchievementCard.apply(card, def, Achievements.is_unlocked(def.get("id", "")))
		_list.add_child(card)


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 120
	root.offset_right = -120
	root.offset_top = 50
	root.offset_bottom = -50
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 12)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	column.add_child(header)

	var title := _label("ACHIEVEMENTS", 40)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_counter = _label("0 / 0 UNLOCKED", 24)
	_counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_counter)

	var close_button := TerminalStyle.text_button("CLOSE", Vector2(150, 46), 26, ACCENT)
	close_button.pressed.connect(close)
	header.add_child(close_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_list)

	_empty_note = _label(
		"No achievements defined yet.\nAdd entries to Achievements.DEFS and they show up here automatically.", 22)
	_empty_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_empty_note)


func _label(text: String, size: int) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", FONT)
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", ACCENT)
	return node
