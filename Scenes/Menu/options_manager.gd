extends Control

@onready var sfx_slider: HSlider = $BasePanel/HBoxContainer/SFX/SfxSlider
@onready var volume_slider: HSlider = $BasePanel/HBoxContainer/MUSIC/VolumeSlider
@onready var percentage_label_volume: Label = $BasePanel/HBoxContainer/MUSIC/percentageLabelVolume
@onready var percentage_label_sfx: Label = $BasePanel/HBoxContainer/SFX/percentageLabelSfx
@export var camera: Camera2D
const BAR_TONE = preload("uid://cmabygqmehtnw")
const PCSELECT_2 = preload("uid://sb4jso5acwm2")
@onready var percentage_label_gamma: Label = $BasePanel/HBoxContainer/GAMMA/percentageLabelGamma
@export var gamma: CanvasModulate
@onready var gamma_slider: HSlider = $BasePanel/HBoxContainer/GAMMA/GammaSlider


func _ready() -> void:
	gamma.color = Global.gammaValue
	percentage_label_gamma.text = str(Global.gammaTextValue)
	gamma_slider.value = Global.gammaTextValue
	sfx_slider.value = Global.sfx_volume
	volume_slider.value = Global.music_volume
	percentage_label_sfx.text = str(sfx_slider.value) + "%"
	percentage_label_volume.text = str(volume_slider.value) + "%"

func _process(_delta: float) -> void:
	_bound_to_camera()

func _bound_to_camera() -> void:
	if camera != null:
		position = camera.get_screen_center_position()

func _on_exit_button_pressed() -> void:
	AudioManager.play_sfx(PCSELECT_2)
	hide()


func _on_check_button_toggled(toggled_on: bool) -> void:
	AudioManager.play_sfx(PCSELECT_2)
	if toggled_on == false:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


func _on_sfx_slider_value_changed(value: float) -> void:
	percentage_label_sfx.text = str(value) + "%"
	AudioManager.set_sfx_volume(value)
	AudioManager.play_sfx(BAR_TONE)
	


func _on_volume_slider_value_changed(value: float) -> void:
	percentage_label_volume.text = str(value) + "%"
	AudioManager.set_music_volume(value)
	AudioManager.play_sfx(BAR_TONE)


func _on_scan_button_toggled(toggled_on: bool) -> void:
	AudioManager.play_sfx(PCSELECT_2)
	if toggled_on == false:
		Global.scanlines = false
	else:
		Global.scanlines = true



#Color(0.298, 0.243, 0.243)
#Color(2.417, 2.183, 2.183, 1.0)

func _on_gamma_slider_value_changed(value: float) -> void:
	var gammaColor = Color(clamp(value / 50, 0.2, 2.5), clamp(value / 100, 0.3, 1.2), clamp(value / 100, 0.3, 1.2))
	gamma.color = Global.gammaValue
	percentage_label_gamma.text = str(value)
	Global.gammaValue = gammaColor
	Global.gammaTextValue = value


func _on_gamma_slider_drag_ended(value_changed: bool) -> void:
	gamma.color = Global.gammaValue
