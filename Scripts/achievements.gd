extends CanvasLayer

const FONT := preload("res://Fonts/home-video/HomeVideo-Regular.ttf")
const UNLOCK_SOUND := preload("res://SOUNDS/barTone2.wav")

const TOAST_SECONDS := 4.0
const TOAST_FADE := 0.4

const DEFS: Array[Dictionary] = []

signal unlocked(id: String)

var _queue: Array[Dictionary] = []
var _showing := false
var _toast: PanelContainer
var _icon: Panel
var _name_label: Label
var _desc_label: Label
var _tween: Tween
var _fade_root: Control


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_toast()
	visible = false

func all_defs() -> Array[Dictionary]:
	return DEFS


func get_def(id: String) -> Dictionary:
	for def in DEFS:
		if def.get("id", "") == id:
			return def
	return {}


func is_unlocked(id: String) -> bool:
	return SaveData.unlocked_achievements().has(id)


func unlocked_count() -> int:
	var total := 0
	for def in DEFS:
		if is_unlocked(def.get("id", "")):
			total += 1
	return total

func unlock(id: String) -> bool:
	if id == "":
		return false
	if not SaveData.mark_achievement(id):
		return false

	var def := get_def(id)
	if def.is_empty():
		push_warning("Unlocked achievement '%s' with no definition." % id)
		unlocked.emit(id)
		return true

	_queue.append(def)
	if not _showing:
		_show_next()
	unlocked.emit(id)
	return true

func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		visible = false
		return

	var def: Dictionary = _queue.pop_front()
	_showing = true
	_name_label.text = str(def.get("name", "???"))
	_desc_label.text = str(def.get("description", ""))

	visible = true
	_fade_root.modulate.a = 0.0
	AudioManager.play_sfx(UNLOCK_SOUND, -4.0, 1.5)

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_fade_root, "modulate:a", 1.0, TOAST_FADE)
	_tween.tween_interval(TOAST_SECONDS)
	_tween.tween_property(_fade_root, "modulate:a", 0.0, TOAST_FADE)
	_tween.tween_callback(_show_next)


func _build_toast() -> void:
	var anchor := Control.new()
	anchor.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	anchor.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	anchor.grow_vertical = Control.GROW_DIRECTION_BEGIN
	anchor.offset_left = -520
	anchor.offset_top = -150
	anchor.offset_right = -28
	anchor.offset_bottom = -28
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(anchor)
	_fade_root = anchor

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 6)
	column.alignment = BoxContainer.ALIGNMENT_END
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor.add_child(column)

	var title := _label("Achievement Unlocked!", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	_toast = AchievementCard.build(FONT)
	_icon = AchievementCard.icon_of(_toast)
	_name_label = AchievementCard.name_of(_toast)
	_desc_label = AchievementCard.desc_of(_toast)
	column.add_child(_toast)


func _label(text: String, size: int) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", FONT)
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", TerminalStyle.RED)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node
