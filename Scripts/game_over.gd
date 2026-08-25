extends CanvasLayer

const FONT := preload("res://Fonts/home-video/HomeVideo-Regular.ttf")
const ALERT_SOUND := preload("res://SOUNDS/barTone.wav")
const TONE_SOUND := preload("res://SOUNDS/barTone2.wav")

const GAME_SCENE := "res://Scenes/Game/game.tscn"
const MENU_SCENE := "res://Scenes/Menu/menu.tscn"

signal game_ended(won: bool)

var is_over := false
var won := false

var _armed := false
var _elapsed := 0.0
var _cause := ""

var _panel: PanelContainer
var _title: Label
var _cause_label: Label
var _stats: Label


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false

	Global.player_caught.connect(_on_player_caught)

func arm() -> void:
	BlackoutHUD.visible = true
	_armed = true
	is_over = false
	won = false
	_elapsed = 0.0
	_cause = ""
	visible = false


func reset() -> void:
	_armed = false
	is_over = false
	won = false
	_elapsed = 0.0
	_cause = ""
	visible = false


func _process(delta: float) -> void:
	if not _armed or is_over:
		return

	_elapsed += delta

	if CoreResources.produced_recipes.size() >= CoreResources.MANUAL_COUNT:
		_end(true)
	elif Global.infection_value >= 100.0:
		_end(false)


func _on_player_caught() -> void:
	_cause = "IT FOUND YOU"

func _infection_cause() -> String:
	if _cause != "":
		return _cause
	if CoreResources.oxygen <= 0.0:
		return "YOU RAN OUT OF AIR"
	if CoreResources.current_heat_zone == 4:
		return "THE COLD TOOK YOU"
	if Global.door_closed:
		return "YOU SEALED YOURSELF IN"
	return "THE INFECTION TOOK HOLD"


func _end(did_win: bool) -> void:
	if is_over:
		return

	is_over = true
	won = did_win
	_armed = false

	var accent := TerminalStyle.GREEN if did_win else TerminalStyle.RED
	_title.text = "CURE SYNTHESISED" if did_win else "RUN LOST"
	_title.add_theme_color_override("font_color", accent)
	_panel.add_theme_stylebox_override("panel",
			TerminalStyle.outline_style(Color(0, 0, 0, 0.96), accent))

	if did_win:
		_cause_label.text = "All %d doses produced. The ship is clean." % CoreResources.MANUAL_COUNT
	else:
		_cause_label.text = _infection_cause()
	_cause_label.add_theme_color_override("font_color", accent)

	_stats.text = "MANUALS %d/%d      DOSES %d/%d      TIME %s" % [
		CoreResources.comms_stage, CoreResources.MANUAL_COUNT,
		CoreResources.produced_recipes.size(), CoreResources.MANUAL_COUNT,
		_format_time(_elapsed),
	]

	BlackoutHUD.visible = false
	Rooms.close_travel_menu()
	Monitor.close()

	AudioManager.stop_music(0.5)
	AudioManager.play_sfx(TONE_SOUND if did_win else ALERT_SOUND, 0.0, 1.6 if did_win else 0.25)

	visible = true
	get_tree().paused = true
	game_ended.emit(did_win)


func _format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%d:%02d" % [total / 60, total % 60]

func _restart() -> void:
	_leave_to(GAME_SCENE)


func _to_menu() -> void:
	_leave_to(MENU_SCENE)


func _leave_to(path: String) -> void:
	get_tree().paused = false
	reset()
	CoreResources.reset_systems()
	Global.reset_player_state()
	Blackout.reset()
	get_tree().change_scene_to_file(path)

func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 46)
	margin.add_theme_constant_override("margin_right", 46)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)

	_title = _label("", 56)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)

	_cause_label = _label("", 28)
	_cause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_cause_label)

	_stats = _label("", 24)
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats.add_theme_color_override("font_color", TerminalStyle.DIM_GREEN)
	column.add_child(_stats)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 18)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(buttons)

	var retry := TerminalStyle.text_button("TRY AGAIN", Vector2(260, 54), 30)
	retry.pressed.connect(_restart)
	buttons.add_child(retry)

	var menu := TerminalStyle.text_button("MAIN MENU", Vector2(260, 54), 30)
	menu.pressed.connect(_to_menu)
	buttons.add_child(menu)


func _label(text: String, size: int) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", FONT)
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", TerminalStyle.GREEN)
	return node
