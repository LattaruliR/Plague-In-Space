extends CanvasLayer

## toasted não entendi se no blackout teria penalidade visual, entao fiz isso: o escuro em si, quao longe
## o grid reboot é, e o prompt de caça de quando o plague ta na sala

const FONT := preload("res://Fonts/home-video/HomeVideo-Regular.ttf")

const GREEN := TerminalStyle.GREEN
const AMBER := TerminalStyle.AMBER
const RED := TerminalStyle.RED
const DARKNESS := 0.5 # how black the blackout gets
const FADE_SPEED := 1.6

var _shade: ColorRect
var _status: Label
var _warning: Label

var _shade_alpha := 0.0
var _message := ""
var _message_time := 0.0


func _ready() -> void:
	layer = 20
	_build_ui()

	Blackout.restore_refused.connect(_on_refused)
	Blackout.power_came_online.connect(func(): _flash("GRID ONLINE - THROW THE SWITCH", 3.0))
	Blackout.hunt_started.connect(_on_hunt_started)
	Blackout.hunt_survived.connect(func(): _flash("IT MOVED ON", 2.5))
	Blackout.threat_warning.connect(_on_threat_warning)
	Global.player_caught.connect(func(): _flash("IT FOUND YOU", 5.0))


func _process(delta: float) -> void:
	if get_tree().current_scene and get_tree().current_scene.name == "Menu":
		visible = false
		return
	visible = true

	var target := DARKNESS if Global.blackout else 0.0
	_shade_alpha = move_toward(_shade_alpha, target, FADE_SPEED * delta)
	_shade.color = Color(0.0, 0.0, 0.0, _shade_alpha)
	_shade.visible = _shade_alpha > 0.001

	if _message_time > 0.0:
		_message_time -= delta
		if _message_time <= 0.0:
			_message = ""

	_update_labels()


func _update_labels() -> void:
	if not Global.blackout:
		_status.text = _message
		_status.add_theme_color_override("font_color", GREEN)
		_warning.text = ""
		return

	if Global.hunting:
		if Global.hiding:
			var side_name := "LEFT" if Global.hide_side == 0 else "RIGHT"
			_warning.text = "HIDDEN - %s" % side_name
			_warning.add_theme_color_override("font_color", GREEN)
		else:
			_warning.text = "IT IS IN THE ROOM"
			_warning.add_theme_color_override("font_color", RED)
	else:
		_warning.text = _message
		_warning.add_theme_color_override("font_color", AMBER)

	if Blackout.power_online:
		_status.text = "POWER RESTORED - THROW THE SWITCH IN THE OFFICE"
		_status.add_theme_color_override("font_color", GREEN)
	else:
		_status.text = "BLACKOUT - GRID REBOOTING %ds" % int(ceil(Blackout.reboot_remaining()))
		_status.add_theme_color_override("font_color", AMBER)


func _on_refused(reason: String) -> void:
	_flash(reason, 3.0)


func _on_hunt_started(_side: int) -> void:
	_flash("SOMETHING CAME IN", 2.0)


func _on_threat_warning(room: int) -> void:
	if Global.blackout:
		return # the sound clues carry it once the lights are out
	_flash("MOVEMENT IN THE %s" % Global.ROOM_NAMES.get(room, "SHIP"), 3.0)


func _flash(text: String, duration: float) -> void:
	_message = text
	_message_time = duration


func _build_ui() -> void:
	_shade = ColorRect.new()
	_shade.color = Color(0, 0, 0, 0)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shade.visible = false
	add_child(_shade)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	column.offset_top = -140
	column.offset_bottom = -30
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override("separation", 8)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)

	_warning = _make_label(40)
	column.add_child(_warning)

	_status = _make_label(26)
	column.add_child(_status)


func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", GREEN)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
