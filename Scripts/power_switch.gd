extends Node2D

## the breaker in the office

const FONT := preload("res://Fonts/home-video/HomeVideo-Regular.ttf")
const GREEN := TerminalStyle.GREEN
const AMBER := TerminalStyle.AMBER
@onready var offline: Panel = $"../../InformationFeed/BasePanel/Offline"
@onready var offline_base: ColorRect = $"../../ButtonSpread/ComputerBase/OfflineBase"
@onready var reboot_time: Timer = $"../../ButtonSpread/ComputerBase/RebootTime"
@onready var booting: ColorRect = $"../../ButtonSpread/ComputerBase/Booting"


@export var lever: AnimatedSprite2D
@export var button: Button
@export var label: Label

var _message := ""
var _message_time := 0.0

func _ready() -> void:
	if button != null and not button.pressed.is_connected(_on_pressed):
		button.pressed.connect(_on_pressed)

	Blackout.restore_refused.connect(_on_restore_refused)
	Blackout.power_came_online.connect(_on_power_online)
	_refresh()

func _process(delta: float) -> void:
	if _message_time > 0.0:
		_message_time -= delta
		if _message_time <= 0.0:
			_message = ""
	_refresh()

func _on_pressed() -> void:
	Blackout.toggle_switch()
	if lever != null and lever.sprite_frames != null and lever.sprite_frames.has_animation("Pressing"):
		lever.play("Pressing")
	_refresh()

func _on_restore_refused(reason: String) -> void:
	_flash(reason)

func _on_power_online() -> void:
	_flash("FLIP\n SWITCH")

func _flash(text: String) -> void:
	_message = text
	_message_time = 3.0

func _refresh() -> void:
	if lever != null and not lever.is_playing():
		var animation := "IdleDown" if Global.blackout else "IdleUp"
		if lever.sprite_frames != null and lever.sprite_frames.has_animation(animation):
			lever.animation = animation

	if label == null:
		return

	if _message != "":
		label.text = _message
		label.add_theme_color_override("font_color", AMBER)
		return

	if Global.blackout:
		if Blackout.power_online:
			label.text = "POWER:\n READY"
			label.add_theme_color_override("font_color", GREEN)
		else:
			offline_base.visible = true
			offline.visible = true
			label.text = "REBOOT:\n %ds" % int(ceil(Blackout.reboot_remaining()))
			label.add_theme_color_override("font_color", AMBER)
	else:
		offline_base.visible = false
		offline.visible = false
		label.text = "POWER:\n ON"
		label.add_theme_color_override("font_color", GREEN)
