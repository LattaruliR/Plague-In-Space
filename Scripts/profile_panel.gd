extends Control

const FONT := preload("res://Fonts/home-video/HomeVideo-Regular.ttf")
const CLICK_SOUND := preload("res://SOUNDS/selecting.wav")
const ALERT_SOUND := preload("res://SOUNDS/barTone.wav")

const ACCENT := Color(0.61, 0, 0.0824)
const DANGER := Color(1.0, 0.25, 0.2)

const ARM_DELAY := 0.6

@export var best_time_label: Label
@export var achievements_button: Button
@export var delete_button: Button

var _layer: CanvasLayer
var _summary: Label
var _confirm_button: Button
var _arm_left := 0.0


func _ready() -> void:
	_build_confirm()
	_refresh_best_time()

	if achievements_button != null:
		achievements_button.pressed.connect(_on_achievements_pressed)
	if delete_button != null:
		delete_button.pressed.connect(_open_confirm)

	set_process(false)


func _process(delta: float) -> void:
	if _arm_left <= 0.0:
		return
	_arm_left -= delta
	if _arm_left <= 0.0:
		_confirm_button.disabled = false
		_confirm_button.text = "DELETE"
	else:
		_confirm_button.text = "DELETE (%.1f)" % _arm_left


func _unhandled_input(event: InputEvent) -> void:
	if _layer.visible and event.is_action_pressed("ui_cancel"):
		_close_confirm()
		get_viewport().set_input_as_handled()

func _refresh_best_time() -> void:
	if best_time_label == null:
		return

	var parts: Array[String] = []
	if SaveData.has_best_time(false):
		parts.append("YOUR BEST TIME: %s" % SaveData.format_time(SaveData.best_time(false)))
	if SaveData.has_best_time(true):
		parts.append("HARD: %s" % SaveData.format_time(SaveData.best_time(true)))

	if parts.is_empty():
		best_time_label.text = "YOUR BEST TIME: --:--"
	else:
		best_time_label.text = "\n".join(parts)


func _on_achievements_pressed() -> void:
	AudioManager.play_sfx(CLICK_SOUND, -6.0, 1.1)
	AchievementsUI.open()

func _open_confirm() -> void:
	var lines: Array[String] = []
	if SaveData.has_best_time(false):
		lines.append("Best time: %s" % SaveData.format_time(SaveData.best_time(false)))
	if SaveData.has_best_time(true):
		lines.append("Best time (hard): %s" % SaveData.format_time(SaveData.best_time(true)))
	lines.append("Runs played: %d" % SaveData.runs_played())
	if SaveData.cure_found():
		lines.append("Cure found: yes")
	lines.append("Achievements unlocked: %d" % SaveData.unlocked_achievements().size())

	_summary.text = "\n".join(lines)

	_layer.visible = true
	_arm_left = ARM_DELAY
	_confirm_button.disabled = true
	_confirm_button.text = "DELETE (%.1f)" % ARM_DELAY
	set_process(true)
	AudioManager.play_sfx(ALERT_SOUND, -6.0, 0.6)


func _close_confirm() -> void:
	_layer.visible = false
	_arm_left = 0.0
	set_process(false)
	AudioManager.play_sfx(CLICK_SOUND, -8.0, 0.9)


func _do_delete() -> void:
	if not _layer.visible or _arm_left > 0.0:
		return

	SaveData.clear_all()
	_close_confirm()
	_refresh_best_time()
	AudioManager.play_sfx(ALERT_SOUND, -2.0, 0.35)

func _build_confirm() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 75
	_layer.visible = false
	add_child(_layer)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(shade)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
			TerminalStyle.outline_style(Color(0, 0, 0, 0.97), DANGER))
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var title := _label("DELETE SAVE?", 40, DANGER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var warning := _label("This erases your profile permanently.\nIt cannot be undone.", 22, DANGER)
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(warning)

	_summary = _label("", 22, ACCENT)
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_summary)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 18)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(buttons)

	var cancel := TerminalStyle.text_button("KEEP IT", Vector2(230, 52), 28, ACCENT)
	cancel.pressed.connect(_close_confirm)
	buttons.add_child(cancel)

	_confirm_button = TerminalStyle.text_button("DELETE", Vector2(230, 52), 28, DANGER)
	_confirm_button.pressed.connect(_do_delete)
	buttons.add_child(_confirm_button)


func _label(text: String, size: int, colour: Color) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", FONT)
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", colour)
	return node
