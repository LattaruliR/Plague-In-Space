extends Control

@onready var sfx_slider: HSlider = $BasePanel/HBoxContainer/SFX/SfxSlider
@onready var volume_slider: HSlider = $BasePanel/HBoxContainer/MUSIC/VolumeSlider
@onready var percentage_label_volume: Label = $BasePanel/HBoxContainer/MUSIC/percentageLabelVolume
@onready var percentage_label_sfx: Label = $BasePanel/HBoxContainer/SFX/percentageLabelSfx


func _ready() -> void:
	sfx_slider.value = Global.sfx_volume
	volume_slider.value = Global.music_volume
	percentage_label_sfx.text = str(sfx_slider.value) + "%"
	percentage_label_volume.text = str(volume_slider.value) + "%"



func _on_exit_button_pressed() -> void:
	$"../Selecting".play()
	hide()


func _on_check_button_toggled(toggled_on: bool) -> void:
	$"../Selecting".play()
	if toggled_on == false:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


func _on_sfx_slider_value_changed(value: float) -> void:
	percentage_label_sfx.text = str(value) + "%"
	AudioManager.set_sfx_volume(value)
	$"../BarTone".play()


func _on_volume_slider_value_changed(value: float) -> void:
	percentage_label_volume.text = str(value) + "%"
	AudioManager.set_music_volume(value)
	$"../BarTone".play()
