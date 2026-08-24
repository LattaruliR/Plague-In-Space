extends Node2D

const PRESS_SOUND := preload("res://SOUNDS/selecting.wav")
const ALERT_SOUND := preload("res://SOUNDS/barTone.wav")

const CHANNEL_NAMES := ["R", "G", "B"]
const CHANNEL_COLORS := [
	Color(1.0, 0.4, 0.4),
	Color(0.4, 1.0, 0.4),
	Color(0.45, 0.6, 1.0),
]

var _root: Control
var _dial_labels: Array[Label] = []
var _dial_buttons: Array[Button] = []
var _recipe_labels: Array[Label] = []
var _swatch: ColorRect
var _sum_label: Label
var _produce_button: Button
var _status_label: Label

var _message := ""
var _message_time := 0.0


func _ready() -> void:
	if CoreResources.recipes.is_empty():
		CoreResources.roll_recipes()
	if CoreResources.kitchen_combo.size() != 3:
		CoreResources.kitchen_combo = [0, 0, 0]

	_build_ui()

	CoreResources.recipe_unlocked.connect(_on_recipe_unlocked)
	CoreResources.system_sabotaged.connect(func(_r): _refresh())
	CoreResources.system_repaired.connect(func(_r): _refresh())
	_refresh()


func _process(delta: float) -> void:
	if _message_time > 0.0:
		_message_time -= delta
		if _message_time <= 0.0:
			_message = ""
			_refresh()


func _on_recipe_unlocked(_index: int) -> void:
	_flash("NEW RECIPE RECEIVED FROM ARCHIVE")
	_refresh()

func _on_dial_changed(channel: int, step: int) -> void:
	if Global.blackout or CoreResources.is_sabotaged(Global.Room.KITCHEN):
		return

	var value: int = CoreResources.kitchen_combo[channel] + step
	value = wrapi(value, 0, CoreResources.KITCHEN_DIAL_MAX + 1)
	CoreResources.kitchen_combo[channel] = value

	AudioManager.play_sfx(PRESS_SOUND, -6.0, 0.9 + 0.1 * channel)
	_refresh()


func _on_produce_pressed() -> void:
	if Global.blackout:
		_flash("NO POWER")
		return
	if CoreResources.is_sabotaged(Global.Room.KITCHEN):
		_flash("BENCH SABOTAGED")
		return

	if CoreResources.get_pending_recipes().is_empty():
		_flash("NO RECIPE ON FILE")
		AudioManager.play_sfx(ALERT_SOUND, -6.0, 0.6)
		_refresh()
		return

	var produced := CoreResources.try_produce_cure(CoreResources.kitchen_combo)
	if produced >= 0:
		_flash("DOSE %d PRODUCED - CHARGE SPENT" % (produced + 1))
	elif CoreResources.power < CoreResources.CURE_CHARGE_COST:
		_flash("NOT ENOUGH POWER")
	else:
		_flash("MIXTURE REJECTED")

	_refresh()


func _flash(text: String) -> void:
	_message = text
	_message_time = 3.5

func _refresh() -> void:
	var combo := CoreResources.kitchen_combo
	var offline: bool = Global.blackout or CoreResources.is_sabotaged(Global.Room.KITCHEN)

	for channel in _dial_labels.size():
		_dial_labels[channel].text = str(combo[channel])

	CoreResources.num_display = combo[0] + combo[1] + combo[2]
	CoreResources.kitchen_sum = [CoreResources.num_display]
	_sum_label.text = "SUM: %02d" % CoreResources.num_display

	var dial_max := float(CoreResources.KITCHEN_DIAL_MAX)
	_swatch.color = Color(combo[0] / dial_max, combo[1] / dial_max, combo[2] / dial_max)

	for index in _recipe_labels.size():
		_recipe_labels[index].text = _recipe_text(index)
		if CoreResources.produced_recipes.has(index):
			_recipe_labels[index].add_theme_color_override("font_color", TerminalStyle.DIM_GREEN)
		else:
			_recipe_labels[index].add_theme_color_override("font_color", TerminalStyle.GREEN)

	for button in _dial_buttons:
		button.disabled = offline
	_produce_button.disabled = offline or CoreResources.get_pending_recipes().is_empty()

	if _message != "":
		_status_label.text = _message
	elif CoreResources.is_sabotaged(Global.Room.KITCHEN):
		_status_label.text = "BENCH SABOTAGED - REBOOT FROM THE OFFICE"
	elif offline:
		_status_label.text = "NO POWER - CONSOLE OFFLINE"
	else:
		_status_label.text = "DOSES PRODUCED: %d/%d   CHARGES: %d" % [
			CoreResources.produced_recipes.size(), CoreResources.MANUAL_COUNT, CoreResources.power
		]

	_root.modulate = Color(0.4, 0.4, 0.4) if offline else Color.WHITE


func _recipe_text(index: int) -> String:
	if not CoreResources.unlocked_recipes.has(index):
		return "MANUAL %d   - - -   LOCKED" % (index + 1)

	var recipe := CoreResources.get_recipe(index)
	var values := "%d / %d / %d" % [recipe[0], recipe[1], recipe[2]]
	if CoreResources.produced_recipes.has(index):
		return "MANUAL %d   %s   DONE" % [index + 1, values]
	return "MANUAL %d   %s" % [index + 1, values]

func _build_ui() -> void:
	_root = Control.new()
	_root.size = Vector2(880, 480)
	_root.position = Vector2(-440, -260)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(column)

	var header := TerminalStyle.panel()
	var title := TerminalStyle.label(TerminalStyle.spaced("SYNTHESIS BENCH"), 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	TerminalStyle.wrap_in_margin(header, title, 10)
	column.add_child(header)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)

	body.add_child(_build_manual_panel())
	body.add_child(_build_mixer_panel())

	_status_label = TerminalStyle.label("", 24)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_status_label)


func _build_manual_panel() -> Control:
	var panel := TerminalStyle.panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	TerminalStyle.wrap_in_margin(panel, box, 14)

	box.add_child(TerminalStyle.label("MANUALS ON FILE", 26))

	for index in CoreResources.MANUAL_COUNT:
		var entry := TerminalStyle.label("", 24)
		_recipe_labels.append(entry)
		box.add_child(entry)

	return panel


func _build_mixer_panel() -> Control:
	var panel := TerminalStyle.panel()

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	TerminalStyle.wrap_in_margin(panel, box, 14)

	var dials := HBoxContainer.new()
	dials.add_theme_constant_override("separation", 14)
	dials.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(dials)

	for channel in 3:
		dials.add_child(_build_dial(channel))

	var readout := HBoxContainer.new()
	readout.add_theme_constant_override("separation", 14)
	readout.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(readout)

	_swatch = ColorRect.new()
	_swatch.custom_minimum_size = Vector2(58, 40)
	readout.add_child(_swatch)

	_sum_label = TerminalStyle.label("SUM: 00", 26)
	readout.add_child(_sum_label)

	_produce_button = TerminalStyle.text_button("PRODUCE", Vector2(220, 48), 30)
	_produce_button.pressed.connect(_on_produce_pressed)
	box.add_child(_produce_button)

	return panel


func _build_dial(channel: int) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.alignment = BoxContainer.ALIGNMENT_CENTER

	var name_label := TerminalStyle.label(CHANNEL_NAMES[channel], 24, CHANNEL_COLORS[channel])
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)

	var up := TerminalStyle.text_button("+", Vector2(74, 40), 28)
	up.pressed.connect(_on_dial_changed.bind(channel, 1))
	_dial_buttons.append(up)
	box.add_child(up)

	var value := TerminalStyle.label("0", 44, CHANNEL_COLORS[channel])
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dial_labels.append(value)
	box.add_child(value)

	var down := TerminalStyle.text_button("-", Vector2(74, 40), 28)
	down.pressed.connect(_on_dial_changed.bind(channel, -1))
	_dial_buttons.append(down)
	box.add_child(down)

	return box
